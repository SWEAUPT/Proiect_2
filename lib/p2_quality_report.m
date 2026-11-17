function T = p2_quality_report(x, fs)
% P2_QUALITY_REPORT Is this recording a usable voice-cloning reference?
%
%   T = p2_quality_report(x, fs)
%
% Zero-shot cloning copies EVERYTHING in the reference, not only the voice:
% room echo, hum, clipping distortion and background music all come back in
% the clone. These checks catch the common problems before you spend time
% synthesising. The thresholds are rules of thumb, not standards.
%
% Columns: Check | Value | Target | Status ("OK" or "WARN").

x = x(:);
dur = numel(x) / fs;
peak = max(abs(x));
peakDb = 20 * log10(max(peak, eps));
clipFrac = mean(abs(x) >= 0.999);

% Frame energy on 20 ms frames: the quiet frames estimate the noise floor,
% the loud ones the speech level. Their difference is a rough SNR.
%   win      20 ms in samples;  fr  the first nFr*win samples as a win-by-nFr matrix
%   eDb      energy of every frame in dB (mean of squares, + eps against log(0))
%   noiseDb  10th percentile of eDb;  speechDb  95th percentile;  snrDb their difference
todo('1.1', 'frame energies and the SNR estimate (win, nFr, eDb, noiseDb, speechDb, snrDb)');

% Share of the file that actually contains speech.
try
    roi = detectSpeech(x, fs);
    speechSec = sum(roi(:, 2) - roi(:, 1) + 1) / fs;
catch
    speechSec = sum(eDb > noiseDb + 10) * win / fs;     % fallback: energy gate
end
speechFrac = speechSec / max(dur, eps);

checks  = ["Duration (s)"; "Peak level (dBFS)"; "Clipped samples (%)"; ...
           "Estimated SNR (dB)"; "Speech share (%)"];
values  = [dur; peakDb; 100 * clipFrac; snrDb; 100 * speechFrac];
targets = ["5 - 30"; "-12 .. -1"; "< 0.1"; "> 30"; "> 60"];
% ok(k) is true when check k meets its target (one logical per row of targets).
todo('1.2', 'the pass/fail vector ok, one entry per check');
status = repmat("WARN", numel(ok), 1);
status(ok) = "OK";

T = table(checks, round(values, 2), targets, status, ...
    'VariableNames', {'Check', 'Value', 'Target', 'Status'});
end
