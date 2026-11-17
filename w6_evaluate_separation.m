function R = w6_evaluate_separation(spk, x, mixes, sepOut, varargin)
% W6_EVALUATE_SEPARATION Week 6: speech to text, listening test, level sweep.
%
%   R = w6_evaluate_separation(spk, x, mixes, sepOut)
%   ... 'Fs', 16000, 'FsEval', 8000
%   ... 'ListenMix', "A_mf_en", 'ListenModels', ["sepformer" "tiger"]
%   ... 'Levels', [-12 -6 0 6 12]       level of speaker 2 vs speaker 1, dB
%   ... 'SweepPair', [1 2], 'SweepModels', [...]
%   ... 'OutDir', "audio/sep/separated", 'Plot', true, 'Play', true
%
% R.werTable, R.summaryWER   word error rates
% R.listening                score sheet (1-5) to fill in by hand
% R.sweep                    SNRi of speaker 2 per level (rows) and model
%
% WHAT THIS WEEK IS ABOUT
% 1. SPEECH TO TEXT. Every signal is transcribed with Whisper large-v3 in
%    the project's Python environment (it knows Romanian) and compared with
%    the text the speaker was given:
%        WER = (substitutions + deletions + insertions) / words said
%    Three transcripts per speaker: CLEAN (the TTS source alone - the
%    floor: errors here come from the TTS or Whisper, not separation),
%    MIXTURE (the whole mixture) and EXTRACTED (the model's output). For
%    Romanian, compare EXTRACTED with CLEAN, not with 0.
% 2. LISTENING. Numbers do not replace ears. Score each output 1-5:
%      5 only the target voice, natural    4 faint other voice / artefacts
%      3 other voice clearly audible, words still easy
%      2 hard to follow                    1 wrong speaker or unusable
% 3. LEVEL SWEEP. Real speakers are rarely equally loud. Speaker 2 is made
%    quieter and louder than speaker 1 and every 2-speaker model separates
%    every version. The quieter a speaker, the more there is to gain - and
%    the easier it is for a model to miss it.

p = inputParser;
p.addParameter('Fs', 16000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('FsEval', 8000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('ListenMix', "A_mf_en", @(s) ischar(s) || isstring(s));
p.addParameter('ListenModels', ["sepformer" "tiger"], @(s) isstring(s) || iscellstr(s));
% Whole, distinct dB values: they name the sweep files and the table rows.
p.addParameter('Levels', [-12 -6 0 6 12], @(v) isnumeric(v) && ~isempty(v) && all(v == round(v)) && numel(unique(v)) == numel(v));
p.addParameter('SweepPair', [1 2], @(v) isnumeric(v) && numel(v) == 2);
p.addParameter('SweepModels', ["convtasnet" "sepformer" "mossformer2" "tiger"], @(s) isstring(s) || iscellstr(s));
p.addParameter('OutDir', fullfile(fileparts(mfilename('fullpath')), 'audio', 'sep', 'separated'), ...
    @(s) ischar(s) || isstring(s));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.addParameter('Play', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;
FS = o.Fs;

% ---------------- 1. speech to text ----------------
for lang = unique(spk.Lang)'
    % Every signal of a speaker in this language, so Whisper loads once.
    files = spk.File(spk.Lang == lang);
    for i = 1:numel(mixes)
        inLang = spk.Lang(mixes(i).src) == lang;
        if ~any(inLang), continue; end
        files = [files; mixes(i).file]; %#ok<AGROW>
        for mdl = string(fieldnames(sepOut.(mixes(i).name)))'
            r = sepOut.(mixes(i).name).(mdl);
            oi = r.outIdx(inLang);
            files = [files; r.files(oi(oi > 0))]; %#ok<AGROW>
        end
    end
    p2_transcribe(unique(files, 'stable'), lang);   % fills the cache
end
rows = {};
for i = 1:numel(mixes)
    for c = 1:numel(mixes(i).src)
        k = mixes(i).src(c);
        lang = spk.Lang(k);
        % The two baselines of speaker k: its clean TTS file and the whole
        % mixture, each transcribed in lang and scored against spk.Text(k).
        todo('6.1', 'baseline word error rates werClean and werMix');
        for mdl = string(fieldnames(sepOut.(mixes(i).name)))'
            r = sepOut.(mixes(i).name).(mdl);
            if r.outIdx(c) == 0, continue; end
            hyp = p2_transcribe(r.files(r.outIdx(c)), lang);
            rows{end + 1} = table(string(mixes(i).name), mdl, spk.Id(k), lang, ...
                round(werClean, 2), round(werMix, 2), round(p2_wer(spk.Text(k), hyp), 2), hyp, ...
                'VariableNames', {'Mixture', 'Model', 'Source', 'Lang', 'WER_clean', ...
                'WER_mixture', 'WER_extracted', 'Transcript'}); %#ok<AGROW>
        end
    end
end
R.werTable = vertcat(rows{:});
R.summaryWER = unstack(groupsummary(R.werTable, ["Mixture" "Model"], "mean", "WER_extracted"), ...
    "mean_WER_extracted", "Model", GroupingVariables = "Mixture");
fprintf('[W6] Mean word error rate of the extracted speakers:\n');
disp(R.summaryWER);

% ---------------- 2. listening ----------------
iL = find(string({mixes.name}) == o.ListenMix, 1);
models = string(o.ListenModels);
models = models(isfield(sepOut.(o.ListenMix), models));
if logical(o.Play)
    p2_listen(mixes(iL).x, FS, "mixture " + o.ListenMix);
    for mdl = models
        r = sepOut.(o.ListenMix).(mdl);
        for c = find(r.outIdx > 0)
            p2_listen(r.Y(:, r.outIdx(c)), FS, mdl + " -> " + spk.Id(mixes(iL).src(c)));
        end
    end
end
nSrc = numel(mixes(iL).src);
R.listening = table(repelem(models(:), nSrc), repmat(spk.Id(mixes(iL).src), numel(models), 1), ...
    nan(numel(models) * nSrc, 1), 'VariableNames', {'Model', 'Source', 'Score_1to5'});

% ---------------- 3. level sweep ----------------
mixDir = fileparts(mixes(1).file);
L = o.Levels(:);
files = strings(numel(L), 1);
S = cell(numel(L), 1);
for j = 1:numel(L)
    % Speaker 1 at 0 dB, speaker 2 at L(j) dB: mixture mx and its sources S{j}.
    todo('6.2', 'mixture of the sweep pair at level L(j)');
    files(j) = fullfile(mixDir, sprintf('sweep_%s_%s_%+03d.wav', ...
        spk.Id(o.SweepPair(1)), spk.Id(o.SweepPair(2)), L(j)));
    p2_write_if_changed(files(j), mx, FS);
end
sm = string(o.SweepModels);
sweep = nan(numel(L), numel(sm));
for m = 1:numel(sm)
    Ys = p2_separate(files, sm(m), 'NumSpeakers', 2, 'OutDir', o.OutDir);
    for j = 1:numel(L)
        % Same rule as Week 5 (8 kHz); keep the SNRi of speaker 2 only.
        todo('6.3', 'SNRi of speaker 2 at level L(j) for model m');
    end
end
R.sweep = array2table(round(sweep, 1), 'VariableNames', cellstr(sm), ...
    'RowNames', compose('%+d dB', L));
fprintf('[W6] SNRi of %s when it is quieter/louder than %s:\n', ...
    spk.Id(o.SweepPair(2)), spk.Id(o.SweepPair(1)));
disp(R.sweep);

R.figures = gobjects(0);
if logical(o.Plot)
    R.figures = figure('Name', 'W6 level sweep', 'Color', 'w', 'Position', [80 80 760 420]);
    plot(L, sweep, '-o', 'LineWidth', 1.4); grid on;
    xlabel(sprintf('Level of %s relative to %s (dB)', spk.Id(o.SweepPair(2)), spk.Id(o.SweepPair(1))), ...
        'Interpreter', 'none');
    ylabel(sprintf('SNRi of %s (dB)', spk.Id(o.SweepPair(2))), 'Interpreter', 'none');
    legend(sm, 'Location', 'best');
    title('Separating a quieter (left) or louder (right) speaker');
end
end
