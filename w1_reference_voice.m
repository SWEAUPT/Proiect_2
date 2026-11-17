function ref = w1_reference_voice(varargin)
% W1_REFERENCE_VOICE Week 1: a reference voice, its quality, its spectrograms.
%
%   ref = w1_reference_voice()                         % Audio Toolbox sample
%   ref = w1_reference_voice('Source', "file", 'File', "audio/my_reference.wav")
%   ref = w1_reference_voice('Source', "record", 'File', "audio/my_reference.wav")
%   ... 'Fs', 24000          analysis rate (KittenTTS 2 writes 24 kHz)
%   ... 'WindowsMs', [5 25 100]  STFT window lengths for the trade-off figure
%   ... 'Plot', true, 'Play', true
%
% Returns ref with fields x, fs, file, info, quality (table), figures.
%
% WHAT THIS WEEK IS ABOUT
%   1. A zero-shot voice cloner copies EVERYTHING in its reference: room
%      echo, hum, clipping. p2_quality_report checks that first.
%   2. A spectrogram cuts the signal into short windows and Fourier-
%      transforms each one (STFT). A window of T seconds separates
%      frequencies about 1/T Hz apart: short windows are sharp in time,
%      long ones in frequency. The three-panel figure shows this trade-off;
%      at about 100 ms the individual harmonics of the voice appear.
%   3. The mel spectrogram spaces its bands the way the ear does (dense at
%      low frequencies). Neural TTS models predict this representation.
%
% The default source is a recording that ships with Audio Toolbox
% ("Counting-16-44p1-mono-15secs.wav", a man counting), so nobody's
% personal voice is needed. Clone only your own voice or one whose owner
% agreed.

p = inputParser;
p.addParameter('Source', "sample", @(s) ismember(string(s), ["sample" "file" "record"]));
p.addParameter('File', "", @(s) ischar(s) || isstring(s));
p.addParameter('Fs', 24000, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('RecordSeconds', 12, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('WindowsMs', [5 25 100], @(v) isnumeric(v) && ~isempty(v));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.addParameter('Play', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;

switch string(o.Source)
    case "sample"
        file = "Counting-16-44p1-mono-15secs.wav";
    case "file"
        file = string(o.File);
    case "record"
        file = string(o.File);
        if file == "", error('Project2:NoFile', 'Recording needs ''File'' to save to.'); end
        rec = audiorecorder(o.Fs, 16, 1);
        fprintf('[W1] Recording %g s - read aloud, quiet room, ~20 cm from the mic...\n', o.RecordSeconds);
        recordblocking(rec, o.RecordSeconds);
        audiowrite(file, getaudiodata(rec), o.Fs);
        fprintf('[W1] Saved %s\n', file);
end

[x, fs, info] = p2_load_audio(char(file), o.Fs);
ref = struct('x', x, 'fs', fs, 'file', string(info.file), 'info', info);
fprintf('[W1] Reference: %s\n     %d Hz -> analysed at %d Hz, %.1f s\n', ...
    info.file, info.fsOriginal, fs, info.durationSec);

ref.quality = p2_quality_report(x, fs);
ref.figures = gobjects(0);
if logical(o.Play), p2_listen(x, fs, 'reference'); end
if ~logical(o.Plot), return; end

% Waveform: when there is sound and how loud - but not WHO is speaking.
t = (0:numel(x) - 1) / fs;
f1 = figure('Name', 'W1 waveform', 'Color', 'w', 'Position', [100 100 1000 260]);
plot(t, x, 'Color', [0.2 0.4 0.7]); grid on;
xlabel('Time (s)'); ylabel('Amplitude'); title('Reference waveform');

f2 = p2_plot_window_tradeoff(x, fs, o.WindowsMs);

% Log-mel spectrogram: 80 bands, 0-8 kHz, 25 ms windows, 10 ms hop.
% melSpectrogram returns the band powers m (bands x frames) and the frame
% times tm; the image below needs both.
todo('1.3', 'mel spectrogram m and its frame times tm (melSpectrogram)');
f3 = figure('Name', 'W1 mel spectrogram', 'Color', 'w', 'Position', [100 100 1000 320]);
mdb = 10 * log10(m + eps);
imagesc(tm, 1:80, mdb); axis xy; colormap(turbo); colorbar;
clim([max(mdb(:)) - 80, max(mdb(:))]);
xlabel('Time (s)'); ylabel('mel band');
title('Reference - log-mel spectrogram (80 bands, 0-8 kHz)');
ref.figures = [f1 f2 f3];
end
