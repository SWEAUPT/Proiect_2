function [T, Ymatched, outIdx] = p2_separation_snr(S, Y, labels)
% P2_SEPARATION_SNR How well was each original source extracted?
%
%   [T, Ymatched, outIdx] = p2_separation_snr(S, Y, labels)
%
% S is N-by-C (true sources, as returned by p2_mix), Y is N-by-K (network
% outputs). A separator returns its outputs in an arbitrary order, so each
% source is first paired with the output that matches it: the pairing with
% the highest total SNR over all one-to-one assignments wins. Ymatched(:,c)
% is the output paired with source c (zeros if K < C); outIdx(c) its column.
%
% Columns, per source s and its extracted version s_r:
%   SNRin_dB  SNR of the untouched mixture used as s_r - the starting point
%   SNR_dB    10*log10( sum(s.^2) / sum((s - s_r).^2) )   (the project's SNR)
%   SNRi_dB   SNR_dB - SNRin_dB: what separation gained
%   SISNR_dB  scale-invariant SNR: s_r is first projected onto s, so a pure
%             gain error does not count. Large SISNR but small SNR = the
%             speaker is clean but at the wrong level.

C = size(S, 2);
K = size(Y, 2);
N = min(size(S, 1), size(Y, 1));
S = S(1:N, :);
Y = Y(1:N, :);
mix = sum(S, 2);
if nargin < 3 || isempty(labels), labels = "source " + (1:C); end

snrMat = -inf(C, K);
for c = 1:C
    for k = 1:K
        snrMat(c, k) = snr_db(S(:, c), Y(:, k));
    end
end
% Score used for the pairing: a silent source (SNR -inf against every
% output) or a NaN output would make every sum -inf or NaN and hide the
% sources that can be paired, so scores are floored at -1000 dB.
score = snrMat;
score(~(score > -1000)) = -1000;

% Best one-to-one assignment. C <= 3 and K <= 6, so brute force is instant.
% Try every choice of nUse sources (nchoosek), every choice of nUse outputs
% and every order of those outputs (perms); keep the one whose summed
% score entries are largest. outIdx(c) = output paired with source c,
% 0 for a source left without an output.
todo('5.3', 'best one-to-one pairing outIdx of sources and outputs');

Ymatched = zeros(N, C);
snrIn = nan(C, 1); snrOut = nan(C, 1); si = nan(C, 1);
for c = 1:C
    s = S(:, c);
    snrIn(c) = snr_db(s, mix);
    if outIdx(c) > 0
        Ymatched(:, c) = Y(:, outIdx(c));
        snrOut(c) = snrMat(c, outIdx(c));
        si(c) = sisnr_db(s, Ymatched(:, c));
    end
end
labels = string(labels);
T = table(labels(:), outIdx(:), round(snrIn, 2), round(snrOut, 2), ...
    round(snrOut - snrIn, 2), round(si, 2), 'VariableNames', ...
    {'Source', 'Output', 'SNRin_dB', 'SNR_dB', 'SNRi_dB', 'SISNR_dB'});
end

% =====================================================================
function v = snr_db(s, sr)
% The project's SNR (header). max(..., eps) keeps a perfect s_r finite.
todo('5.1', 'SNR of the extracted signal sr against the source s, in dB');
end

function v = sisnr_db(s, sr)
% Project sr onto s (target = <sr,s>/<s,s> * s); the rest of sr is error.
todo('5.2', 'scale-invariant SNR: projection target, then SNR of target vs the rest');
end
