function [P, T, fig] = w2_voice_fingerprint(x, fs, label, varargin)
% W2_VOICE_FINGERPRINT Week 2: measurable properties of one voice.
%
%   [P, T] = w2_voice_fingerprint(ref.x, ref.fs, "reference")
%   ... 'Plot', false
%
% P is the full profile (p2_voice_profile), T a one-row summary table.
%
% WHAT THIS WEEK IS ABOUT
%   "The same voice" is several separate physical properties. A clone can
%   match one and miss another, so each is measured on its own:
%     pitch F0      how fast the vocal folds vibrate: median over voiced
%                   frames, and the spread in semitones,
%                   12*log2(f95/f5), the musical scale the ear uses
%     formants      F1-F3, resonances of the vocal tract, by Linear
%                   Prediction (LPC). They shape vowels and depend on the
%                   length of the tract.
%     LTAS          long-term average spectrum: the colour of the voice AND
%                   of the recording chain
%     MFCC          compact spectral envelope (timbre); c0 = loudness, dropped
%     centroid      brightness
%   Typical adult median F0: men about 85-155 Hz, women 165-255 Hz. A pitch
%   tracker returns a number even for silence, so only frames that are
%   periodic (harmonic ratio > 0.6) and well above the noise floor count.

p = inputParser;
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});

if nargin < 3, label = "voice"; end
P = p2_voice_profile(x, fs, label);
T = table(string(label), round(P.f0Median, 1), round(P.f0RangeSt, 1), ...
    round(P.formants(1)), round(P.formants(2)), round(P.formants(3)), ...
    round(P.centroidHz), round(100 * P.voicedShare), ...
    'VariableNames', {'Voice', 'MedianF0_Hz', 'F0Spread_st', 'F1_Hz', 'F2_Hz', ...
    'F3_Hz', 'Centroid_Hz', 'Voiced_pct'});
fprintf('[W2] %s: F0 %.1f Hz (spread %.1f st), F1-F3 %s Hz, centroid %.0f Hz, %d%% voiced\n', ...
    label, P.f0Median, P.f0RangeSt, mat2str(round(P.formants)), P.centroidHz, ...
    round(100 * P.voicedShare));

fig = gobjects(0);
if logical(p.Results.Plot)
    fig = p2_plot_voices({x}, fs, string(label), {P});
end
end
