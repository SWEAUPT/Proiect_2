function [wer, nErr, nRef] = p2_wer(refText, hypText)
% P2_WER Word error rate of a transcript against the text that was spoken.
%
%   wer = p2_wer("the cat sat", "the cat sat down")    % 1/3 = 0.333
%
% WER = (substitutions + deletions + insertions) / words in the reference,
% from the word-level edit distance. 0 = perfect; it can exceed 1 when the
% transcript contains many extra words (for example both speakers of a
% mixture). Case and punctuation are ignored. Romanian ș/ț are written with
% a comma below or, in older fonts, with a cedilla (ş/ţ); both count as the
% same letter, otherwise every such word would be an error.

r = words(refText);
h = words(hypText);
nRef = numel(r);
% Edit distance by dynamic programming: d(i+1,j+1) = fewest edits that turn
% the first i reference words into the first j transcript words. First row
% and column: only insertions / deletions. Every other cell is the minimum
% of deletion (d above + 1), insertion (d left + 1) and substitution
% (d diagonal + 1 if the words differ, + 0 if they are equal).
todo('3.2', 'word-level edit distance table d and nErr');
wer = nErr / max(nRef, 1);
end

% =====================================================================
function w = words(t)
t = lower(string(t));
t = replace(t, ["ş" "ţ" "Ş" "Ţ"], ["ș" "ț" "ș" "ț"]);
% Keep letters (any alphabet - MATLAB regexp has no \p{L}), digits and
% apostrophes; everything else separates words.
c = char(t);
c(~(isletter(c) | isstrprop(c, 'digit') | c == '''')) = ' ';
w = split(strtrim(regexprep(string(c), "\s+", " ")));
w = w(w ~= "");
end
