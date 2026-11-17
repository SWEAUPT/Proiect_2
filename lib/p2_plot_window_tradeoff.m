function fig = p2_plot_window_tradeoff(x, fs, windowsMs)
% P2_PLOT_WINDOW_TRADEOFF Same sound, three STFT window lengths.
%
%   p2_plot_window_tradeoff(x, fs)                 % 5, 25 and 100 ms
%   p2_plot_window_tradeoff(x, fs, [10 40 80])
%
% The uncertainty principle of the STFT, made visible: a window of T seconds
% resolves frequencies about 1/T Hz apart.
%   short window (5 ms, 200 Hz bins)  -> sharp in time: plosives, onsets;
%                                       harmonics smear into one band
%   long window (100 ms, 10 Hz bins)  -> individual harmonics of the voice
%                                       appear as lines; onsets blur
% Speech models settle around 25-50 ms because both matter.

if nargin < 3, windowsMs = [5 25 100]; end
x = x(:);
fig = figure('Name', 'STFT window trade-off', 'Color', 'w', ...
             'Position', [80 80 1100 760]);
tl = tiledlayout(fig, numel(windowsMs), 1, 'TileSpacing', 'compact');
for k = 1:numel(windowsMs)
    win = round(windowsMs(k) / 1000 * fs);
    nfft = max(256, 2^nextpow2(win));
    [S, F, T] = stft(x, fs, Window = hann(win, "periodic"), ...
        OverlapLength = round(0.75 * win), FFTLength = nfft, ...
        FrequencyRange = "onesided");
    SdB = 20 * log10(abs(S) + eps);
    ax = nexttile(tl);
    imagesc(ax, T, F / 1000, SdB);
    axis(ax, 'xy');
    ylim(ax, [0 min(5, fs / 2000)]);
    clim(ax, max(SdB(:)) + [-70 0]);       % same 70 dB range in every panel
    colormap(ax, turbo);
    title(ax, sprintf('Window %g ms  |  frequency resolution ~%.0f Hz', ...
        windowsMs(k), fs / win));
    ylabel(ax, 'kHz');
end
xlabel(tl, 'Time (s)');
cb = colorbar(ax); cb.Layout.Tile = 'east'; ylabel(cb, 'dB');
end
