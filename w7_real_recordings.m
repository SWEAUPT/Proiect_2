function recTable = w7_real_recordings(spk, x, varargin)
% W7_REAL_RECORDINGS Week 7 (part 1): separation outside the ideal case.
%
%   recTable = w7_real_recordings(spk, x, 'Loudspeakers', true)
%   recTable = w7_real_recordings(spk, x, 'Live', true)
%   ... 'Pair', [1 2]    speakers played / read aloud
%   ... 'Models', [...], 'Fs', 16000, 'RecordSeconds', 8
%   ... 'AudioDir', "audio/sep", 'Plot', true, 'Play', true
%
% Adding vectors (Weeks 4-6) is the ideal case. In a room the microphone
% also hears echo, noise and the colouring of the loudspeakers.
%   Loudspeakers  speaker 1 on the LEFT channel, speaker 2 on the RIGHT.
%                 Place the boxes ~1 m apart, the microphone in front of
%                 them; the mixture is recorded while it plays.
%   Live          two people read their sentences (shown on screen) at the
%                 same time into one microphone.
% An exact SNR is impossible here: what reached the microphone is not s but
% s filtered by the room. The recordings are judged by speech to text
% (the better-fitting of the two texts, since the output order is
% arbitrary), by listening and by the spectrogram.
%
% Both parts need hardware and are off unless asked for; with both off the
% function returns an empty table.

p = inputParser;
p.addParameter('Loudspeakers', false, @(b) islogical(b) || isnumeric(b));
p.addParameter('Live', false, @(b) islogical(b) || isnumeric(b));
p.addParameter('Pair', [1 2], @(v) isnumeric(v) && numel(v) == 2);
p.addParameter('Models', ["convtasnet" "sepformer" "mossformer2" "tiger"], @(s) isstring(s) || iscellstr(s));
p.addParameter('Fs', 16000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('RecordSeconds', 8, @(v) isnumeric(v) && isscalar(v));
p.addParameter('AudioDir', fullfile(fileparts(mfilename('fullpath')), 'audio', 'sep'), ...
    @(s) ischar(s) || isstring(s));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.addParameter('Play', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;
FS = o.Fs;
pair = o.Pair;
mixDir = fullfile(o.AudioDir, 'mixtures');
outDir = fullfile(o.AudioDir, 'separated');
if ~isfolder(mixDir), mkdir(mixDir); end

recTable = table(strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), strings(0, 1), ...
    'VariableNames', {'Recording', 'Model', 'Output', 'BestWER', 'Transcript'});
recs = struct('name', {}, 'file', {});
if logical(o.Loudspeakers)
    % The two sources at equal level, one per channel (left, right), scaled
    % together to a 0.9 peak.
    todo('7.2', 'two-channel signal stereo: speaker 1 left, speaker 2 right');
    rec = audiorecorder(FS, 16, 1);
    record(rec); pause(0.3);
    playblocking(audioplayer(stereo, FS));
    pause(0.5); stop(rec);
    f = string(fullfile(mixDir, "rec_loudspeakers.wav"));
    audiowrite(f, getaudiodata(rec), FS);
    recs(end + 1) = struct('name', "2 loudspeakers", 'file', f);
end
if logical(o.Live)
    fprintf(['[W7] Two people: read these at the same time, start after "GO":\n' ...
        '  1: %s\n  2: %s\n'], spk.Text(pair(1)), spk.Text(pair(2)));
    rec = audiorecorder(FS, 16, 1);
    disp('GO'); recordblocking(rec, o.RecordSeconds); disp('stop');
    f = string(fullfile(mixDir, "rec_live.wav"));
    audiowrite(f, getaudiodata(rec), FS);
    recs(end + 1) = struct('name', "2 live speakers", 'file', f);
end
if isempty(recs)
    fprintf('[W7] No recording requested (Loudspeakers / Live are off).\n');
    return
end

langs = unique(spk.Lang(pair));
for i = 1:numel(recs)
    xr = audioread(recs(i).file);
    if logical(o.Plot)
        figure('Name', "W7 " + recs(i).name, 'Color', 'w', 'Position', [80 80 1000 260]);
        stft(xr, FS, Window = hann(512, "periodic"), OverlapLength = 384, FrequencyRange = "onesided");
        title("Recorded mixture: " + recs(i).name);
    end
    for mdl = string(o.Models)
        % Recordings are new every run, so their cached separation is stale.
        [Y, info] = p2_separate(recs(i).file, mdl, 'NumSpeakers', 2, 'OutDir', outDir, 'Force', true);
        Y = Y{1};
        for c = 1:min(2, size(Y, 2))
            if logical(o.Play)
                p2_listen(Y(:, c), FS, recs(i).name + ", " + mdl + ", output " + c);
            end
            % The language is unknown per output: try each speaker's own.
            % For every language of the pair: transcribe output c in it and
            % score it against each speaker of that language; keep the
            % lowest WER in w and its transcript in best.
            todo('7.3', 'best WER w and transcript best of output c');
            recTable(end + 1, :) = {recs(i).name, mdl, c, round(w, 2), best}; %#ok<AGROW>
        end
    end
end
disp(recTable);
end
