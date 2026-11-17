function fig = p2_plot_separation(S, Ymatched, fs, labels, titleText)
% P2_PLOT_SEPARATION Original source next to the extracted one, per speaker.
%
%   p2_plot_separation(S, Ymatched, fs, labels, "SepFormer, mixture A")
%
% Left column: the true source s. Right column: what the network extracted
% for it, s_r (as paired by p2_separation_snr). Shared colour scale. Look
% for "leakage": stripes of the OTHER speaker that survive in s_r, usually
% faint and in the low harmonics, where both voices carry most energy.

C = size(S, 2);
labels = string(labels);
win = round(0.032 * fs);
spec = @(x) stft(x, fs, Window = hann(win, "periodic"), ...
    OverlapLength = round(0.75 * win), FFTLength = 2^nextpow2(win), ...
    FrequencyRange = "onesided");
[~, F, T] = spec(S(:, 1));
D = cell(C, 2);
for c = 1:C
    D{c, 1} = 20 * log10(abs(spec(S(:, c))) + eps);
    D{c, 2} = 20 * log10(abs(spec(Ymatched(:, c))) + eps);
end
top = max(cellfun(@(m) max(m(:)), D(:)));

fig = figure('Name', 'Separation result', 'Color', 'w', ...
    'Position', [60 60 1200 230 * C]);
tl = tiledlayout(fig, C, 2, 'TileSpacing', 'compact');
title(tl, titleText, 'Interpreter', 'none');
heads = ["original  ", "extracted  "];
for c = 1:C
    for j = 1:2
        ax = nexttile(tl);
        imagesc(ax, T, F, D{c, j});
        axis(ax, 'xy');
        clim(ax, [top - 70, top]);
        colormap(ax, turbo);
        ylim(ax, [0 fs / 2]);
        ylabel(ax, 'Hz');
        title(ax, heads(j) + labels(c), 'Interpreter', 'none');
    end
end
xlabel(ax, 'Time (s)');
end
