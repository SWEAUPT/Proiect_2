function T = p2_compare_profiles(ref, varargin)
% P2_COMPARE_PROFILES How far is each candidate voice from the reference?
%
%   T = p2_compare_profiles(refProfile, candProfile1, candProfile2, ...)
%
% One row per candidate. Every column is a DISTANCE: 0 = identical to the
% reference, larger = further away. No single number means "good clone".
% The numbers only mean something next to a baseline - always include at
% least one voice that is NOT a clone of the reference (a different
% built-in voice), so you can see what "unrelated speaker" looks like.
%
%   dF0_st      |median F0 difference|, semitones. ~1 st is clearly audible.
%   dRange_st   |difference in pitch spread|, semitones (intonation liveliness)
%   dF1_pct, dF2_pct   relative formant shifts, %
%   ltasRms_dB  RMS difference between normalised long-term spectra over
%               100-4000 Hz, dB
%   mfccDist    Euclidean distance between MFCC c1..c12 means

rows = numel(varargin);
name = strings(rows, 1);
dF0 = nan(rows, 1); dRange = nan(rows, 1);
dF1 = nan(rows, 1); dF2 = nan(rows, 1);
ltas = nan(rows, 1); mfccD = nan(rows, 1);
for k = 1:rows
    c = varargin{k};
    name(k)   = c.label;
    % The four definitions are in the header above (semitones, %).
    todo('3.1', 'pitch and formant distances dF0, dRange, dF1, dF2 of candidate k');
    % Both LTAS curves must share a frequency grid; they do when both
    % profiles were computed at the same sample rate. Only 100-4000 Hz is
    % compared: a reference recorded at 8 kHz (telephone quality) has no
    % energy above 4 kHz, and log(0) there would dominate the result.
    if isequal(size(c.ltasDb), size(ref.ltasDb))
        band = ref.ltasF >= 100 & ref.ltasF <= 4000;
        ltas(k) = sqrt(mean((c.ltasDb(band) - ref.ltasDb(band)) .^ 2));
    end
    mfccD(k) = norm(c.mfccMean - ref.mfccMean);
end
T = table(name, round(dF0, 2), round(dRange, 2), round(dF1, 1), round(dF2, 1), ...
    round(ltas, 2), round(mfccD, 2), 'VariableNames', ...
    {'Voice', 'dF0_st', 'dRange_st', 'dF1_pct', 'dF2_pct', 'ltasRms_dB', 'mfccDist'});
end
