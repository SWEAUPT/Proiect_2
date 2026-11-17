% MAIN Single entry point of Project 2: KittenTTS 2 voices and speaker separation.
%
% Runs the weeks in order, up to LAST_WEEK:
%   W1 reference voice + spectrograms -> W2 voice fingerprint ->
%   W3 KittenTTS 2 cloning (+ Romanian) -> W4 speakers + mixtures ->
%   W5 separation, four models, SNR -> W6 speech to text, listening,
%   level sweep -> W7 real recordings + dashboard
%
% Set LAST_WEEK to the week you are in: each week reuses what the earlier
% ones computed, and every synthesis, separation and transcript is cached
% on disk, so re-running is fast. Tables (CSV) and figures (PNG) for the
% report are saved in results/.
%
% CONFIGURATION
%   LAST_WEEK        1..7
%   REFERENCE_SOURCE "sample" (Audio Toolbox recording), "file" (your WAV at
%                    REFERENCE_FILE) or "record" (record it now)
%   MODELS           separation models compared in Weeks 5-7
%   DO_LOUDSPEAKERS  Week 7: play 2 speakers on 2 boxes, record with 1 mic
%   DO_LIVE          Week 7: two people talk at once into 1 mic
%   PLAY_AUDIO       false = no sound (e.g. on a machine without speakers)
%
% Setup once: setup_tts.ps1 and setup_separation.ps1 (see README.md).
% Tests: run_all_tests (or run_all_tests('Week', 5)).

LAST_WEEK        = 7;
REFERENCE_SOURCE = "sample";
REFERENCE_FILE   = fullfile(pwd, 'audio', 'my_reference.wav');
MODELS           = ["convtasnet" "sepformer" "mossformer2" "tiger"];
DO_LOUDSPEAKERS  = false;
DO_LIVE          = false;
PLAY_AUDIO       = ~batchStartupOptionUsed;
SEED             = 7;      % same seed + same text = same synthesised audio

clc;
root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
addpath(root, fullfile(root, 'lib'));
addpath(genpath(fullfile(root, 'models', 'separateSpeakers')));
global PROJECT2_PLAY %#ok<GVMIS>
PROJECT2_PLAY = PLAY_AUDIO;
resultsDir = fullfile(root, 'results');
save_ = @(name, obj) p2_save_result(resultsDir, name, obj);

fprintf('\n=================================================================\n');
fprintf('   PROJECT 2 - KITTENTTS 2 VOICES AND SPEAKER SEPARATION\n');
fprintf('   Weeks 1-%d | GPU available: %d\n', LAST_WEEK, canUseGPU);
fprintf('=================================================================\n\n');

% -----------------------------------------------------------------
% Week 1: reference voice, quality, spectrogram trade-off, mel spectrogram
% -----------------------------------------------------------------
fprintf('[W1] Reference voice\n');
ref = w1_reference_voice('Source', REFERENCE_SOURCE, 'File', REFERENCE_FILE, 'Play', PLAY_AUDIO);
disp(ref.quality);
save_('w1_quality', ref.quality);
save_('w1_figures', ref.figures);
if LAST_WEEK < 2, return; end

% -----------------------------------------------------------------
% Week 2: voice fingerprint
% -----------------------------------------------------------------
fprintf('\n[W2] Voice fingerprint\n');
[refProfile, fingerprint, fig] = w2_voice_fingerprint(ref.x, ref.fs, "reference");
save_('w2_fingerprint', fingerprint);
save_('w2_figures', fig);
if LAST_WEEK < 3, return; end

% -----------------------------------------------------------------
% Week 3: KittenTTS 2 - built-in voices, a clone, Romanian
% -----------------------------------------------------------------
fprintf('\n[W3] Voice cloning with KittenTTS 2\n');
clone = w3_clone_voice(ref, refProfile, 'Seed', SEED, 'Play', PLAY_AUDIO);
save_('w3_clone_comparison', clone.comparison);
save_('w3_across_languages', clone.acrossLanguages);
save_('w3_figures', clone.figures);
if LAST_WEEK < 4, return; end

% -----------------------------------------------------------------
% Week 4: speakers from KittenTTS 2, mixtures by adding vectors
% -----------------------------------------------------------------
fprintf('\n[W4] Speakers and mixtures\n');
[spk, x, mixes, fig] = w4_make_mixtures('Seed', SEED, 'Play', PLAY_AUDIO);
save_('w4_speakers', spk(:, ["Id" "Voice" "Gender" "MeasuredGender" "MedianF0_Hz" "Lang" "Duration_s" "Text"]));
save_('w4_figures', fig);
if LAST_WEEK < 5, return; end

% -----------------------------------------------------------------
% Week 5: separation with four models, SNR
% -----------------------------------------------------------------
fprintf('\n[W5] Separation\n');
[snrTable, summarySNRi, sepOut, fig] = w5_separate_mixtures(mixes, spk, 'Models', MODELS);
save_('w5_snr', snrTable);
save_('w5_summary_snri', summarySNRi);
save_('w5_figures', fig);
if LAST_WEEK < 6, return; end

% -----------------------------------------------------------------
% Week 6: speech to text, listening, level sweep
% -----------------------------------------------------------------
fprintf('\n[W6] Speech to text, listening, level sweep\n');
ev = w6_evaluate_separation(spk, x, mixes, sepOut, 'SweepModels', MODELS, 'Play', PLAY_AUDIO);
save_('w6_wer', ev.werTable);
save_('w6_summary_wer', ev.summaryWER);
save_('w6_listening_sheet', ev.listening);
save_('w6_level_sweep', ev.sweep);
save_('w6_figures', ev.figures);
if LAST_WEEK < 7, return; end

% -----------------------------------------------------------------
% Week 7: real recordings (optional hardware) + dashboard
% -----------------------------------------------------------------
fprintf('\n[W7] Real recordings and dashboard\n');
recTable = w7_real_recordings(spk, x, 'Loudspeakers', DO_LOUDSPEAKERS, 'Live', DO_LIVE, ...
    'Models', MODELS, 'Play', PLAY_AUDIO);
if ~isempty(recTable), save_('w7_recordings', recTable); end
fig = w7_dashboard(summarySNRi, ev.summaryWER, ev.sweep, 'CloneComparison', clone.comparison);
save_('w7_dashboard', fig);

fprintf('\n=================================================================\n');
fprintf('   DONE. Tables and figures for the report: %s\n', resultsDir);
fprintf('=================================================================\n\n');
