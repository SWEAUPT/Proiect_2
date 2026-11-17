function [mix, S] = p2_mix(sources, levelsDb)
% P2_MIX Mix speakers by adding their signal vectors.
%
%   [mix, S] = p2_mix({s1, s2})              % equal loudness
%   [mix, S] = p2_mix({s1, s2, s3}, [0 -6 0]) % speaker 2 is 6 dB quieter
%
% Every source is padded with silence to the longest one, scaled to unit
% RMS and then to its level in dB, and the columns are summed. S holds the
% sources EXACTLY as they are inside the mixture (N-by-C) - that is the
% ground truth s every extracted signal is compared with. Comparing with the
% original unscaled file instead would count the level change as error.
%
% The mixture is scaled to a 0.9 peak so that it never clips; the same gain
% is applied to S, so mix == sum(S, 2) always holds.

C = numel(sources);
if nargin < 2 || isempty(levelsDb), levelsDb = zeros(1, C); end
if numel(levelsDb) ~= C
    error('Project2:MixLevels', 'Need one level per source (%d), got %d.', C, numel(levelsDb));
end
% A silent source has rms 0: dividing by it would turn the whole mixture into NaN.
silent = find(cellfun(@(s) isempty(s) || ~any(s(:)), sources), 1);
if ~isempty(silent)
    error('Project2:SilentSource', 'Source %d is empty or silent - check its synthesis or recording.', silent);
end
% Steps (see the header): pad to the longest source N, column k of S =
% source k / rms * 10^(level/20), mix = sum of the columns, then ONE gain
% g = 0.9 / max|mix| applied to both mix and S.
todo('4.1', 'the sources S at their levels and the mixture mix');
end
