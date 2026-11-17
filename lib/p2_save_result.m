function files = p2_save_result(dirName, name, obj)
% P2_SAVE_RESULT Save a table (CSV) or figures (PNG) for the report.
%
%   p2_save_result("results", "w5_snr", snrTable)      % results/w5_snr.csv
%   p2_save_result("results", "w5_figures", figs)      % results/w5_figures_1.png ...
%
% Tables keep their row names (e.g. the level sweep). Figures are exported
% at 150 dpi; an array of figures gets numbered files. Invalid or deleted
% figure handles are skipped. Returns the files written.

if ~isfolder(dirName), mkdir(dirName); end
files = strings(0, 1);
if istable(obj)
    f = fullfile(dirName, name + ".csv");
    writetable(obj, f, 'WriteRowNames', ~isempty(obj.Properties.RowNames), 'Encoding', 'UTF-8');
    files = string(f);
elseif isa(obj, 'matlab.ui.Figure') || isa(obj, 'matlab.graphics.Graphics')
    obj = obj(isgraphics(obj, 'figure'));
    for k = 1:numel(obj)
        suffix = "";
        if numel(obj) > 1, suffix = "_" + k; end
        f = fullfile(dirName, name + suffix + ".png");
        exportgraphics(obj(k), f, 'Resolution', 150);
        files(end + 1, 1) = string(f); %#ok<AGROW>
    end
end
end
