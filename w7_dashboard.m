function fig = w7_dashboard(summarySNRi, summaryWER, sweep, varargin)
% W7_DASHBOARD Week 7 (part 2): one figure with the project's main results.
%
%   fig = w7_dashboard(summarySNRi, summaryWER, sweep)
%   ... 'CloneComparison', T   Week 3 distance table (optional panel)
%   ... 'Title', "Project 2 - KittenTTS 2 voices and speaker separation"
%
% Four panels: mean SNR improvement and mean word error rate per mixture
% and model (heat maps, numbers printed in every cell), the level sweep,
% and - if given - how far the clone is from the reference compared with
% unrelated voices. Missing cells (a 2-speaker model on a 3-speaker
% mixture) stay blank. The figure is meant to go into the report.

p = inputParser;
p.addParameter('CloneComparison', [], @(t) isempty(t) || istable(t));
p.addParameter('Title', "Project 2 - KittenTTS 2 voices and speaker separation", ...
    @(s) ischar(s) || isstring(s));
p.parse(varargin{:});
o = p.Results;

fig = figure('Name', 'W7 dashboard', 'Color', 'w', 'Position', [40 40 1300 820]);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, o.Title, 'FontWeight', 'bold');

heat(nexttile(tl), summarySNRi, 'Mean SNR improvement (dB) - higher is better', '%.1f', parula);
heat(nexttile(tl), summaryWER, 'Mean word error rate of extracted speakers - lower is better', ...
    '%.2f', flipud(parula));

ax = nexttile(tl);
lv = str2double(erase(string(sweep.Properties.RowNames), " dB"));
plot(ax, lv, sweep{:, :}, '-o', 'LineWidth', 1.4); grid(ax, 'on');
legend(ax, sweep.Properties.VariableNames, 'Location', 'best');
xlabel(ax, 'Level of speaker 2 relative to speaker 1 (dB)');
ylabel(ax, 'SNRi of speaker 2 (dB)');
title(ax, 'Level sweep');

ax = nexttile(tl);
T = o.CloneComparison;
if isempty(T)
    axis(ax, 'off');
    text(ax, 0.5, 0.5, 'Week 3 clone comparison not given', 'HorizontalAlignment', 'center');
else
    cols = intersect(["dF0_st" "dF1_pct" "dF2_pct" "ltasRms_dB" "mfccDist"], ...
        string(T.Properties.VariableNames), 'stable');
    b = bar(ax, categorical(cols, cols), T{:, cols}');
    legend(ax, b, string(T{:, 1}), 'Location', 'northwest', 'Interpreter', 'none');
    set(ax, 'TickLabelInterpreter', 'none');      % keep "dF0_st", no subscripts
    grid(ax, 'on'); ylabel(ax, 'distance from reference');
    title(ax, 'Week 3: clone vs unrelated voices (lower = closer)');
end
end

% =====================================================================
function heat(ax, T, ttl, fmt, cmap)
% Heat map of a Mixture-by-Model table; NaN cells stay white.
V = T{:, 2:end};
models = string(T.Properties.VariableNames(2:end));
mixes = string(T{:, 1});
imagesc(ax, V, 'AlphaData', ~isnan(V));
colormap(ax, cmap); colorbar(ax);
set(ax, 'XTick', 1:numel(models), 'XTickLabel', models, ...
    'YTick', 1:numel(mixes), 'YTickLabel', mixes, 'TickLabelInterpreter', 'none');
lim = clim(ax);
% Print V(r,c) in every non-NaN cell with sprintf(fmt, ...). Readable text:
% find the colormap row k of the cell's value, its luminance
% 0.299R + 0.587G + 0.114B; below 0.5 -> white text, otherwise black.
todo('7.1', 'value printed in every heat-map cell, in a readable colour');
title(ax, ttl);
end
