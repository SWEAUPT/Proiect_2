function fig = p2_plot_mixture(S, mix, fs, labels, showF0)
% P2_PLOT_MIXTURE Spectrogram of every source and of their mixture.
%
%   p2_plot_mixture(S, mix, fs, ["Bruno (EN, m)" "Luna (EN, f)"])
%   p2_plot_mixture(..., false)    % without the pitch overlay
%
% All panels share ONE colour scale, so a quiet source looks quiet. The
% window is 32 ms: long enough that the harmonics of a voice show as
% separate horizontal stripes (spacing = F0), short enough to follow them.
%
% On the mixture panel, the pitch contour of every source is drawn on top
% (dots, one colour per speaker, at F0 and 2*F0). This is the key to the
% question "can you SEE that there is more than one speaker?": where two
% harmonic combs with different spacing overlap, there are two voices. For
% two voices of similar pitch the combs coincide and the eye is fooled.

if nargin < 5, showF0 = true; end
C = size(S, 2);
labels = string(labels);
win = round(0.032 * fs);
sig = [num2cell(S, 1), {mix(:)}];
names = [labels(:)', "mixture"];
P = cell(1, C + 1); F = []; T = [];
for k = 1:C + 1
    [s, F, T] = stft(sig{k}, fs, Window = hann(win, "periodic"), ...
        OverlapLength = round(0.75 * win), FFTLength = 2^nextpow2(win), ...
        FrequencyRange = "onesided");
    P{k} = 20 * log10(abs(s) + eps);
end
top = max(cellfun(@(m) max(m(:)), P));

fig = figure('Name', 'Sources and mixture', 'Color', 'w', ...
    'Position', [60 60 1100 220 * (C + 1)]);
tl = tiledlayout(fig, C + 1, 1, 'TileSpacing', 'compact');
cols = lines(C);
for k = 1:C + 1
    ax = nexttile(tl);
    imagesc(ax, T, F, P{k});
    axis(ax, 'xy');
    clim(ax, [top - 70, top]);
    colormap(ax, turbo);
    ylim(ax, [0 min(2000, fs / 2)]);
    ylabel(ax, 'Hz');
    title(ax, names(k), 'Interpreter', 'none');
    if k <= C
        text(ax, 0.005, 0.9, '\bullet', 'Units', 'normalized', ...
            'Color', cols(k, :), 'FontSize', 20);
    end
end
xlabel(ax, 'Time (s)');

if showF0
    hold(ax, 'on');
    for k = 1:C
        pk = p2_voice_profile(S(:, k), fs, names(k));
        f = pk.f0; f(~pk.voiced) = NaN;
        plot(ax, pk.frameTimes, f, '.', 'Color', 'w', 'MarkerSize', 9);
        plot(ax, pk.frameTimes, f, '.', 'Color', cols(k, :), 'MarkerSize', 5);
        plot(ax, pk.frameTimes, 2 * f, '.', 'Color', cols(k, :), 'MarkerSize', 3);
    end
    hold(ax, 'off');
    title(ax, "mixture  -  dots: F0 and 2·F0 of each source (colour as above)", ...
        'Interpreter', 'none');
end
end
