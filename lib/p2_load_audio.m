function [x, fs, info] = p2_load_audio(filePath, targetFs)
% P2_LOAD_AUDIO Read an audio file as a mono column vector at a known rate.
%
%   [x, fs, info] = p2_load_audio(filePath)            % keep the file's rate
%   [x, fs, info] = p2_load_audio(filePath, 24000)     % resample to 24 kHz
%
% Every comparison in this project assumes both signals share one sample rate.
% Spectrogram bins, MFCC filterbanks and pitch frames are all defined in Hz
% and seconds, but computed in samples - compare a 16 kHz file against a
% 24 kHz one without resampling and every frequency axis is silently wrong.

if ~isfile(filePath) && ~isempty(which(filePath))
    filePath = which(filePath);     % e.g. a sample file shipped with Audio Toolbox
end
if ~isfile(filePath)
    error('Project2:NoFile', 'Audio file not found: %s', filePath);
end
[x, fsIn] = audioread(filePath);
info.file       = filePath;
info.fsOriginal = fsIn;
info.channels   = size(x, 2);

x = mean(x, 2);                     % stereo -> mono (average, not left channel)
fs = fsIn;
if nargin >= 2 && ~isempty(targetFs) && targetFs ~= fsIn
    x = resample(x, targetFs, fsIn);
    fs = targetFs;
end
x = x - mean(x);                    % remove DC offset; it biases energy and LPC
info.fs = fs;
info.durationSec = numel(x) / fs;
end
