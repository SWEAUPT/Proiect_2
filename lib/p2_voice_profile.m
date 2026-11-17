function P = p2_voice_profile(x, fs, label)
% P2_VOICE_PROFILE Measurable fingerprint of a voice, from one recording.
%
%   P = p2_voice_profile(x, fs, label)
%
% What a listener calls "the same voice" is several separable properties.
% Each field below measures one of them, so a clone can be wrong in one way
% (right timbre, wrong pitch) and right in another:
%
%   f0 / f0Median / f0RangeSt   PITCH. Fundamental frequency of voiced frames,
%                               its median (Hz) and spread (5th-95th percentile,
%                               in semitones - the musical scale the ear uses).
%   formants                    VOCAL TRACT. Median F1, F2, F3 (Hz) from LPC.
%                               They shape vowels and depend on tract length.
%   ltasF / ltasDb              TIMBRE / RECORDING CHAIN. Long-term average
%                               spectrum, normalised to unit total power so
%                               loudness does not count.
%   mfccMean / mfccStd          TIMBRE, compactly. Mean and spread of MFCC
%                               c1..c12 (c0 is overall loudness and is dropped).
%   centroidHz                  BRIGHTNESS. Mean spectral centroid of speech.

if nargin < 3, label = ""; end
x = x(:);
P.label = string(label);
P.fs = fs;
P.durationSec = numel(x) / fs;

% ---------------- framing shared by pitch and voicing ----------------
win = round(0.040 * fs);            % 40 ms: long enough for 2 periods at 50 Hz
hop = round(0.010 * fs);            % 10 ms hop
ovl = win - hop;

f0 = pitch(x, fs, Range = [60 400], WindowLength = win, ...
           OverlapLength = ovl, Method = "NCF");
hr = harmonicRatio(x, fs, Window = hamming(win, "periodic"), OverlapLength = ovl);

starts = 1:hop:(numel(x) - win + 1);
fr = x(starts' + (0:win - 1));                      % [frames x win]
eDb = 10 * log10(mean(fr .^ 2, 2) + eps);

n = min([numel(f0), numel(hr), numel(eDb)]);
f0 = f0(1:n); hr = hr(1:n); eDb = eDb(1:n);
% A frame counts as voiced only if it is periodic AND clearly above the
% noise floor. Pitch trackers always return a number, even for silence.
%   voiced       harmonic ratio > 0.6 AND energy > 10th percentile of eDb + 15 dB
%   f0Median     median F0 of the voiced frames (Hz)
%   f0RangeSt    spread in semitones: 12*log2(95th / 5th percentile of voiced F0)
%   no voiced frame at all -> both NaN
P.frameTimes = ((0:n - 1)' * hop + win / 2) / fs;
P.f0 = f0;
todo('2.1', 'voiced frames, median F0 and its spread in semitones');
P.voiced = voiced;
P.voicedShare = mean(voiced);

% ---------------- formants by LPC on voiced frames ----------------
P.formants = lpc_formants(x, fs, starts(1:n), win, voiced);

% ---------------- long-term average spectrum ----------------
nfft = 2^nextpow2(round(0.064 * fs));
[pxx, F] = pwelch(x, hann(nfft, "periodic"), nfft / 2, nfft, fs);
keep = F <= min(8000, fs / 2);
P.ltasF  = F(keep);
P.ltasDb = 10 * log10(pxx(keep) / sum(pxx(keep)) + eps);

% ---------------- MFCC and brightness ----------------
c = mfcc(x, fs, Window = hamming(round(0.025 * fs), "periodic"), ...
         OverlapLength = round(0.015 * fs), NumCoeffs = 13, LogEnergy = "Ignore");
cv = c(:, 2:end);                                   % drop c0 (loudness)
speechFrames = c(:, 1) > prctile(c(:, 1), 30);      % ignore the quietest frames
P.mfccMean = mean(cv(speechFrames, :), 1);
P.mfccStd  = std(cv(speechFrames, :), 0, 1);

sc = spectralCentroid(x, fs, Window = hamming(round(0.025 * fs), "periodic"), ...
                      OverlapLength = round(0.015 * fs));
P.centroidHz = mean(sc(speechFrames(1:min(end, numel(sc)))), "omitnan");
end

% =====================================================================
function F = lpc_formants(x, fs, starts, win, voiced)
% Median F1-F3 over voiced frames. Resampling to 10 kHz keeps the LPC order
% small (rule of thumb: 2 + fs/1000) and the first three formants all sit
% below 5 kHz anyway.
fsL = 10000;
xl = resample(x, fsL, fs);
ratio = fsL / fs;
winL = round(win * ratio);
order = 2 + fsL / 1000;
idx = find(voiced);
idx = idx(1:max(1, ceil(numel(idx) / 400)):end);  % cap the work at ~400 frames
est = nan(numel(idx), 3);
for k = 1:numel(idx)
    s0 = round((starts(idx(k)) - 1) * ratio) + 1;
    if s0 + winL - 1 > numel(xl), continue; end
    seg = xl(s0:s0 + winL - 1) .* hamming(winL);
    seg = filter([1 -0.97], 1, seg);                % pre-emphasis
    a = lpc(seg, order);
    if any(~isfinite(a)), continue; end
    % Each resonance is a pair of complex poles: keep one of each pair
    % (imag > 0). Pole angle -> frequency f = angle*fsL/(2*pi); pole radius ->
    % bandwidth bw = -fsL/pi*log(|r|). Formants are the sharp resonances
    % (bw < 400 Hz) above 90 Hz, sorted; est(k,:) = the lowest three.
    todo('2.2', 'formant frequencies from the LPC poles');
end
F = median(est, 1, "omitnan");
end
