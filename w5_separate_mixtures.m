function [snrTable, summarySNRi, sepOut, figs] = w5_separate_mixtures(mixes, spk, varargin)
% W5_SEPARATE_MIXTURES Week 5: separate every mixture with four models; SNR.
%
%   [snrTable, summarySNRi, sepOut] = w5_separate_mixtures(mixes, spk)
%   ... 'Models', ["convtasnet" "sepformer" "mossformer2" "tiger"]
%   ... 'Fs', 16000, 'FsEval', 8000, 'OutDir', "audio/sep/separated"
%   ... 'ShowMix', "B_mm_en", 'ShowModel', "sepformer"   detail figure
%   ... 'PermMix', "A_mf_en", 'PermModel', "tiger"       permutation figure
%   ... 'Plot', true
%
% snrTable     one row per (mixture, model, source)
% summarySNRi  mean SNR improvement per mixture (rows) and model (columns)
% sepOut       sepOut.(mixture).(model) = struct Y, outIdx, files
%
% WHAT THIS WEEK IS ABOUT
%   For a source s and its extracted version s_r
%       SNR = 10*log10( sum(s.^2) / sum((s - s_r).^2) )  dB
%   A network returns the speakers in an arbitrary order, so each source is
%   first paired with the output that fits it best (p2_separation_snr).
%   Columns: SNRin (the mixture itself used as s_r: ~0 dB for two equal
%   speakers, ~-3 dB for three), SNR, SNRi = SNR - SNRin (what separation
%   gained - the fairest single number) and SI-SNR (a correct voice at the
%   wrong level is not counted as error).
%
%   The four models are described in p2_separate. MossFormer2 and TIGER
%   separate 2 speakers only; they are skipped for 3-speaker mixtures.
%
% TWO DECISIONS THAT KEEP THE COMPARISON FAIR
%   - SNR is computed at 8 kHz for all models. The MATLAB models work at
%     8 kHz and output nothing above 4 kHz; at 16 kHz they would lose SNR
%     for bandwidth alone.
%   - Output levels follow one rule (least-squares gains, as
%     separateSpeakers' ConserveEnergy), applied inside p2_separate.
%
% PERMUTATION SWITCHES
%   A model may also CHANGE the order in the middle of the signal. One
%   global pairing cannot fix that, so the SNR collapses although every
%   short piece is well separated. The permutation figure follows, per
%   0.5 s segment, which source each output resembles: crossing lines are
%   a switch. TIGER does this on mixture A.

p = inputParser;
p.addParameter('Models', ["convtasnet" "sepformer" "mossformer2" "tiger"], @(s) isstring(s) || iscellstr(s));
p.addParameter('Fs', 16000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('FsEval', 8000, @(v) isnumeric(v) && isscalar(v));
p.addParameter('OutDir', fullfile(fileparts(mfilename('fullpath')), 'audio', 'sep', 'separated'), ...
    @(s) ischar(s) || isstring(s));
p.addParameter('ShowMix', "B_mm_en", @(s) ischar(s) || isstring(s));
p.addParameter('ShowModel', "sepformer", @(s) ischar(s) || isstring(s));
p.addParameter('PermMix', "A_mf_en", @(s) ischar(s) || isstring(s));
p.addParameter('PermModel', "tiger", @(s) ischar(s) || isstring(s));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;
models = string(o.Models);
FS = o.Fs;
pyModels = ["mossformer2" "tiger"];

% Python models: one call per model for all 2-speaker mixtures, so each
% model loads once. The loop below then reads the cached results.
two = arrayfun(@(m) numel(m.src) == 2, mixes);
for mdl = intersect(models, pyModels, 'stable')
    if any(two)
        p2_separate([mixes(two).file], mdl, 'OutDir', o.OutDir);
    end
end

rows = {};
sepOut = struct();
for mdl = models
    for i = 1:numel(mixes)
        C = numel(mixes(i).src);
        if ismember(mdl, pyModels) && C > 2
            continue
        end
        [Y, info] = p2_separate(mixes(i).file, mdl, 'NumSpeakers', C, 'OutDir', o.OutDir);
        Y = Y{1};
        % Fair comparison: sources and outputs both at o.FsEval (8 kHz),
        % then the SNR table of this mixture and model.
        todo('5.4', 'resample S and Y to FsEval and score them (T, outIdx)');
        sepOut.(mixes(i).name).(mdl) = struct('Y', Y, 'outIdx', outIdx, 'files', info.files);
        T.Mixture = repmat(string(mixes(i).name), height(T), 1);
        T.Model = repmat(mdl, height(T), 1);
        % Conv-TasNet's residual is returned as an extra column; it is not a speaker.
        T.Outputs = repmat(size(Y, 2) - (mdl == "convtasnet"), height(T), 1);
        T.Sec = repmat(round(info.separateSec, 2), height(T), 1);
        T.Device = repmat(info.device, height(T), 1);
        rows{end + 1} = T; %#ok<AGROW>
    end
end
snrTable = vertcat(rows{:});
snrTable = snrTable(:, ["Mixture" "Model" "Source" "Outputs" "SNRin_dB" "SNR_dB" ...
    "SNRi_dB" "SISNR_dB" "Sec" "Device"]);
summarySNRi = unstack(groupsummary(snrTable, ["Mixture" "Model"], "mean", "SNRi_dB"), ...
    "mean_SNRi_dB", "Model", GroupingVariables = "Mixture");
% Keep the mixtures in their defined order, not alphabetical.
[~, ord] = ismember(string({mixes.name}), summarySNRi.Mixture);
summarySNRi = summarySNRi(ord(ord > 0), :);
fprintf('[W5] Mean SNR improvement (dB) per mixture and model:\n');
disp(summarySNRi);

figs = gobjects(0);
if ~logical(o.Plot), return; end

figs(end + 1) = figure('Name', 'W5 SNR improvement', 'Color', 'w', 'Position', [80 80 1000 380]);
G = summarySNRi{:, 2:end};
bar(categorical(summarySNRi.Mixture, summarySNRi.Mixture), G);
legend(summarySNRi.Properties.VariableNames(2:end), 'Location', 'northeastoutside');
ylabel('mean SNRi (dB)'); grid on;
title('How much each model improves the SNR (missing bar = model not applicable)');

iS = find(string({mixes.name}) == o.ShowMix, 1);
if ~isempty(iS) && isfield(sepOut, o.ShowMix) && isfield(sepOut.(o.ShowMix), o.ShowModel)
    r = sepOut.(o.ShowMix).(o.ShowModel);
    Ym = zeros(size(mixes(iS).S));
    n = min(size(Ym, 1), size(r.Y, 1));      % Python outputs can be a few samples short
    Ym(1:n, r.outIdx > 0) = r.Y(1:n, r.outIdx(r.outIdx > 0));
    figs(end + 1) = p2_plot_separation(mixes(iS).S, Ym, FS, spk.Id(mixes(iS).src), ...
        o.ShowModel + ", mixture " + o.ShowMix);
end
iP = find(string({mixes.name}) == o.PermMix, 1);
if ~isempty(iP) && isfield(sepOut, o.PermMix) && isfield(sepOut.(o.PermMix), o.PermModel)
    figs(end + 1) = p2_plot_permutation(mixes(iP).S, sepOut.(o.PermMix).(o.PermModel).Y, FS, ...
        spk.Id(mixes(iP).src), o.PermModel + ", mixture " + o.PermMix + ": which source is in which output?");
end
end
