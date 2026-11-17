function g = p2_gender_from_f0(f0Hz)
% P2_GENDER_FROM_F0 "m" or "f" from a median pitch, by a rule of thumb.
%
%   g = p2_gender_from_f0([127 187 250])     % ["m" "f" "f"]
%
% Typical adult median F0: men about 85-155 Hz, women 165-255 Hz. The
% boundary is 165 Hz. A rule of thumb, not a classifier: children, high
% male voices and low female voices are misjudged. NaN (no voiced frames)
% gives "?".

todo('4.2', 'string array g, same size as f0Hz: "m", "f" or "?"');
end
