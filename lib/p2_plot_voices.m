function fig = p2_plot_voices(signals, fs, labels, profiles)
% P2_PLOT_VOICES Log-mel spectrograms of several voices on ONE colour scale,
% plus their pitch contours and long-term spectra overlaid.
%
%   p2_plot_voices({xRef, xClone, xOther}, fs, ["reference" "clone" "other"])
%   p2_plot_voices(..., {pRef, pClone, pOther})   % reuse p2_voice_profile
%
% Mel spectrograms are what a TTS model actually predicts (or what its codec
% tokens decode to), so this is the closest picture to "what the model sees".
% A shared colour scale matters: with automatic scaling per panel, a quiet
% clone and a loud reference look identical.

n = numel(signals);
labels = string(labels);
if nargin < 4 || isempty(profiles)
    profiles = cell(1, n);
    for k = 1:n
        profiles{k} = p2_voice_profile(signals{k}, fs, labels(k));
    end
end

win = round(0.025 * fs);
M = cell(1, n); Tm = cell(1, n);
for k = 1:n
    [m, ~, t] = melSpectrogram(signals{k}(:), fs, Window = hann(win, "periodic"), ...
        OverlapLength = round(0.015 * fs), NumBands = 80, ...
        FrequencyRange = [0 min(8000, fs / 2)]);
    M{k} = 10 * log10(m + eps);
    Tm{k} = t;
end
top = max(cellfun(@(m) max(m(:)), M));

fig = figure('Name', 'Voice comparison', 'Color', 'w', 'Position', [60 60 1200 820]);
tl = tiledlayout(fig, n + 1, 2, 'TileSpacing', 'compact');
for k = 1:n
    ax = nexttile(tl, [1 2]);
    imagesc(ax, Tm{k}, 1:80, M{k});
    axis(ax, 'xy');
    clim(ax, [top - 80, top]);
    colormap(ax, turbo);
    title(ax, sprintf('%s  -  log-mel spectrogram (80 bands, 0-8 kHz)', labels(k)), ...
        'Interpreter', 'none');
    ylabel(ax, 'mel band');
end
xlabel(ax, 'Time (s)');

cols = lines(n);
ax = nexttile(tl);
hold(ax, 'on');
for k = 1:n
    p = profiles{k};
    f = p.f0; f(~p.voiced) = NaN;
    plot(ax, p.frameTimes, f, '.', 'Color', cols(k, :), 'MarkerSize', 6);
end
hold(ax, 'off'); grid(ax, 'on');
xlabel(ax, 'Time (s)'); ylabel(ax, 'F0 (Hz)');
title(ax, 'Pitch contours (voiced frames only)');
legend(ax, labels, 'Location', 'best', 'Interpreter', 'none');

ax = nexttile(tl);
hold(ax, 'on');
for k = 1:n
    p = profiles{k};
    semilogx(ax, p.ltasF, p.ltasDb, 'Color', cols(k, :), 'LineWidth', 1.2);
end
hold(ax, 'off'); grid(ax, 'on');
set(ax, 'XScale', 'log'); xlim(ax, [80 8000]);
xlabel(ax, 'Frequency (Hz)'); ylabel(ax, 'dB (normalised)');
title(ax, 'Long-term average spectrum');
end
