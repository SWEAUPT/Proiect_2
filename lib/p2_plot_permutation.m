function [fig, R] = p2_plot_permutation(S, Y, fs, labels, titleText, segSec)
% P2_PLOT_PERMUTATION Which speaker is in which output - over time?
%
%   p2_plot_permutation(S, Y, fs, labels, "TIGER, mixture A")
%   [fig, R] = p2_plot_permutation(..., 0.5)    % segment length in s
%
% A separator may return the speakers in any order - that is allowed, and
% p2_separation_snr pairs them up. What is NOT allowed is changing the
% order in the MIDDLE of the signal: output 1 carries speaker A for a while,
% then speaker B. This is called a permutation switch. One global pairing
% cannot fix it, so the SNR collapses, although every short piece may be
% well separated.
%
% For every segment, the correlation between each output and each source
% is computed. One panel per output, one line per source: a clean result
% is one line near 1 all the way; a switch shows as two lines crossing.
% R is sources-by-outputs-by-segments.

if nargin < 6 || isempty(segSec), segSec = 0.5; end
labels = string(labels);
C = size(S, 2);
K = size(Y, 2);
N = min(size(S, 1), size(Y, 1));
seg = round(segSec * fs);
nSeg = floor(N / seg);
R = nan(C, K, nSeg);
for j = 1:nSeg
    r = (j - 1) * seg + (1:seg);
    for c = 1:C
        s = S(r, c);
        if rms(s) < 1e-3 * max(rms(S)), continue; end   % source silent here
        for k = 1:K
            cc = corrcoef(s, Y(r, k));
            R(c, k, j) = abs(cc(1, 2));
        end
    end
end
t = ((1:nSeg) - 0.5) * segSec;

fig = figure('Name', 'Permutation check', 'Color', 'w', 'Position', [80 80 900 200 * K]);
tl = tiledlayout(fig, K, 1, 'TileSpacing', 'compact');
title(tl, titleText, 'Interpreter', 'none');
for k = 1:K
    ax = nexttile(tl);
    plot(ax, t, squeeze(R(:, k, :))', '-o', 'LineWidth', 1.3, 'MarkerSize', 4);
    ylim(ax, [0 1.05]); grid(ax, 'on');
    ylabel(ax, '|corr|');
    title(ax, sprintf('output %d', k));
    legend(ax, labels, 'Location', 'eastoutside', 'Interpreter', 'none');
end
xlabel(ax, 'Time (s)');
end
