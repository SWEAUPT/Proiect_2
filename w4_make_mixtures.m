function [spk, x, mixes, figs] = w4_make_mixtures(varargin)
% W4_MAKE_MIXTURES Week 4: speakers from KittenTTS 2, mixed by adding vectors.
%
%   [spk, x, mixes] = w4_make_mixtures()
%   ... 'Speakers', T     table with Id, Voice, Gender, Lang, Text (see below)
%   ... 'Mixtures', M     cell array {name, speaker indices, description; ...}
%   ... 'Fs', 16000, 'Seed', 7, 'AudioDir', "audio/sep", 'Plot', true, 'Play', true
%
% spk   the speaker table plus measured MedianF0_Hz, MeasuredGender, Duration_s
% x     cell array of speaker signals (column vectors at Fs)
% mixes struct array: name, src (speaker indices), desc, x (mixture),
%       S (the sources EXACTLY as they are inside the mixture), file
%
% WHAT THIS WEEK IS ABOUT
%   Because every voice is synthesised, the clean signal s and the exact
%   words of every speaker are known. That makes Week 5 (SNR) and Week 6
%   (word error rate) exact measurements.
%   Mixing = adding vectors, m = s1 + s2 (+ s3), each speaker at the same
%   RMS level (0 dB). p2_mix returns the scaled sources: they, not the
%   original files, are the ground truth s.
%   The figures answer: can you SEE that there are two speakers? Voiced
%   speech is a comb of harmonics F0, 2F0, 3F0...; two voices with
%   different pitch are two combs with different spacing. With similar
%   pitch (man + man) they overlap and the eye is fooled.
%
% Voice names say nothing about gender (KittenTTS' "Italian" voice is
% male), so the median pitch of every speaker is measured and compared
% with the intended gender: above 165 Hz counts as female.

p = inputParser;
p.addParameter('Speakers', default_speakers(), @istable);
p.addParameter('Mixtures', default_mixtures(), @iscell);
p.addParameter('Fs', 16000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('Seed', 7, @(v) isnumeric(v) && isscalar(v));
p.addParameter('AudioDir', fullfile(fileparts(mfilename('fullpath')), 'audio', 'sep'), ...
    @(s) ischar(s) || isstring(s));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.addParameter('Play', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;
FS = o.Fs;
spk = o.Speakers;

srcDir = fullfile(o.AudioDir, 'sources');
mixDir = fullfile(o.AudioDir, 'mixtures');
if ~isfolder(srcDir), mkdir(srcDir); end
if ~isfolder(mixDir), mkdir(mixDir); end
cloneRef = which('Counting-16-44p1-mono-15secs.wav');

n = height(spk);
x = cell(n, 1);
f0 = nan(n, 1);
dur = nan(n, 1);
for k = 1:n
    wav = fullfile(srcDir, spk.Id(k) + ".wav");
    % The English text normaliser would rewrite Romanian text, so it is
    % switched off for every other language.
    opts = {'Seed', o.Seed, 'TargetFs', FS, 'Normalize', spk.Lang(k) == "en"};
    if spk.Voice(k) == "clone"
        opts = [opts, {'Reference', cloneRef}]; %#ok<AGROW>
    else
        opts = [opts, {'Voice', spk.Voice(k)}]; %#ok<AGROW>
    end
    x{k} = p2_kitten_tts(spk.Text(k), wav, opts{:});
    pk = p2_voice_profile(x{k}, FS, spk.Id(k));
    f0(k) = pk.f0Median;
    dur(k) = numel(x{k}) / FS;
end
spk.File = string(fullfile(srcDir, spk.Id + ".wav"));
spk.MedianF0_Hz = round(f0, 1);
spk.MeasuredGender = p2_gender_from_f0(f0);
spk.Duration_s = round(dur, 2);
disp(spk(:, ["Id" "Voice" "Gender" "MeasuredGender" "MedianF0_Hz" "Lang" "Duration_s"]));
if any(spk.Gender ~= spk.MeasuredGender)
    warning('Project2:GenderMismatch', ['Some voices are not the gender the table ' ...
        'assumes - choose other voices (python kitten_bridge.py voices).']);
end

M = o.Mixtures;
mixes = struct('name', M(:, 1), 'src', M(:, 2), 'desc', M(:, 3));
for i = 1:numel(mixes)
    [mixes(i).x, mixes(i).S] = p2_mix(x(mixes(i).src));
    mixes(i).file = string(fullfile(mixDir, mixes(i).name + ".wav"));
    p2_write_if_changed(mixes(i).file, mixes(i).x, FS);
end
fprintf('[W4] %d speakers, %d mixtures in %s\n', n, numel(mixes), mixDir);

figs = gobjects(0);
if logical(o.Play)
    p2_listen(mixes(1).x, FS, mixes(1).desc);
end
if ~logical(o.Plot), return; end
% The two mixtures that answer the visual question best: different pitch
% (first mixture) and the first same-gender one.
iSame = find(arrayfun(@(m) numel(m.src) == 2 && ...
    numel(unique(spk.Gender(m.src))) == 1, mixes), 1);
for i = unique([1, iSame])
    lbl = spk.Id(mixes(i).src) + " (" + spk.Gender(mixes(i).src) + ")";
    figs(end + 1) = p2_plot_mixture(mixes(i).S, mixes(i).x, FS, lbl); %#ok<AGROW>
end
end

% =====================================================================
function T = default_speakers()
% Each speaker says a different sentence with no numbers, so a transcript
% can be checked word by word. The Romanian man is a clone of the Audio
% Toolbox sample voice; Romanian is not one of KittenTTS 2's listed
% languages, so its pronunciation is imperfect (see Week 3).
T = table( ...
    ["en_m1"; "en_f1"; "en_m2"; "ro_m"; "ro_f"], ...
    ["Bruno"; "Luna"; "Marcus"; "clone"; "Serena"], ...
    ["m"; "f"; "m"; "m"; "f"], ...
    ["en"; "en"; "en"; "ro"; "ro"], ...
    ["The weather station recorded heavy rain over the mountains this morning."; ...
     "Please remember to bring your notebook to the lecture on Thursday."; ...
     "A quiet river flows past the old mill at the edge of the village."; ...
     "Astăzi este o zi frumoasă de toamnă la Timișoara."; ...
     "Studenții au terminat proiectul și pregătesc prezentarea finală."], ...
    'VariableNames', {'Id', 'Voice', 'Gender', 'Lang', 'Text'});
end

function M = default_mixtures()
M = {
    "A_mf_en",    [1 2],   "2 speakers, man + woman, English"
    "B_mm_en",    [1 3],   "2 speakers, man + man, English"
    "C_mf_ro",    [4 5],   "2 speakers, man + woman, Romanian"
    "D_ff_enro",  [2 5],   "2 speakers, woman + woman, English + Romanian"
    "E_3_en",     [1 2 3], "3 speakers, English"
    "F_3_enro",   [1 2 4], "3 speakers, English + Romanian"
    };
end
