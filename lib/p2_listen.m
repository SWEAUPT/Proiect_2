function p2_listen(x, fs, label)
% P2_LISTEN Play a signal if audio output is available; never stop the project scripts.
%
% Listening is half of this project - numbers only confirm what the ear finds.
% But a Live Script also runs in -batch mode and on machines without a sound
% device, where sound() throws. Then the script just reports and carries on.
if nargin < 3, label = ''; end
global PROJECT2_PLAY %#ok<GVMIS>
if isequal(PROJECT2_PLAY, false), return; end
try
    fprintf('Playing %s (%.1f s)...\n', label, numel(x) / fs);
    x = x(:) / max(1, max(abs(x)));      % never clip on playback
    sound(x, fs);
    pause(numel(x) / fs + 0.3);          % let it finish before the next one
catch ME
    fprintf('(no audio output: %s)\n', ME.message);
end
end
