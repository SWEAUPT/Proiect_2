function written = p2_write_if_changed(file, x, fs)
% P2_WRITE_IF_CHANGED Write a WAV only if its samples changed.
%
%   written = p2_write_if_changed(file, x, fs)
%
% Separation results are cached per mixture and count as stale once the
% mixture file is newer. Rewriting identical audio on every run would
% therefore redo every separation. Written as 32-bit float, so a mixture
% is stored exactly.

written = false;
x = x(:);
if isfile(file)
    old = audioread(file);
    if isequal(size(old), size(x)) && max(abs(old - x)) < 1e-6
        return
    end
end
audiowrite(file, x, fs, BitsPerSample = 32);
written = true;
end
