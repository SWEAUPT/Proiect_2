function [x, fs, info] = p2_kitten_tts(text, outWav, varargin)
% P2_KITTEN_TTS Synthesise speech with KittenTTS 2 through the Python bridge.
%
%   [x, fs] = p2_kitten_tts(text, outWav)                         % default voice
%   [x, fs] = p2_kitten_tts(text, outWav, 'Voice', 'Bruno')       % built-in voice
%   [x, fs] = p2_kitten_tts(text, outWav, 'Reference', 'me.wav')  % clone
%   ... 'Force', true    re-synthesise even if outWav already exists
%   ... 'TargetFs', 24000  resample the returned signal (the file is untouched)
%   ... 'ReferenceText', "..."  what the reference says (else Whisper transcribes it)
%   ... 'Seed', 7          reproducible sampling - same seed, same audio
%   ... 'Normalize', false skip the ENGLISH text normaliser (use for Romanian)
%
% The result is CACHED in outWav: if the file exists it is simply loaded.
% Synthesis takes seconds to minutes, and re-running a Live Script section
% should not re-synthesise every sentence. Delete the file (or Force) to
% regenerate.
%
% Requires the project's Python environment: run setup_tts.ps1 once.

p = inputParser;
p.addParameter('Voice', '', @(s) ischar(s) || isstring(s));
p.addParameter('Reference', '', @(s) ischar(s) || isstring(s));
p.addParameter('Force', false, @(b) islogical(b) || isnumeric(b));
p.addParameter('TargetFs', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));
p.addParameter('ReferenceText', '', @(s) ischar(s) || isstring(s));
p.addParameter('Seed', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v)));
p.addParameter('Normalize', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
py = fullfile(projectRoot, '.venv', 'Scripts', 'python.exe');
bridge = fullfile(projectRoot, 'kitten_bridge.py');
outWav = char(outWav);
if ~isfolder(fileparts(outWav)) && ~isempty(fileparts(outWav))
    mkdir(fileparts(outWav));
end

info = struct('cached', false, 'synthSec', NaN, 'command', '');
if isfile(outWav) && ~logical(o.Force)
    info.cached = true;
else
    if ~isfile(py)
        error('Project2:NoVenv', ['Project Python environment not found (%s). ' ...
            'Run setup_tts.ps1 in the project folder first.'], py);
    end
    if strlength(o.Reference) > 0
        ref = char(o.Reference);
        if ~isfile(ref), error('Project2:NoReference', 'Reference not found: %s', ref); end
        args = sprintf('clone --reference "%s"', ref);
        if strlength(o.ReferenceText) > 0
            args = sprintf('%s --reference-text "%s"', args, ...
                strrep(char(o.ReferenceText), '"', ''''));
        end
    else
        args = 'say';
        if strlength(o.Voice) > 0, args = sprintf('say --voice "%s"', o.Voice); end
    end
    if ~isempty(o.Seed), args = sprintf('%s --seed %d', args, round(o.Seed)); end
    if ~logical(o.Normalize), args = [args ' --no-normalize']; end
    % Double quotes inside the text would end the shell argument early.
    safeText = strrep(char(text), '"', '''');
    cmd = sprintf('"%s" "%s" %s --text "%s" --out "%s"', py, bridge, args, safeText, outWav);
    info.command = cmd;
    [status, out] = system(cmd);
    res = p2_bridge_json(out);
    if status ~= 0 || isempty(res) || ~res.ok
        if ~isempty(res) && isfield(res, 'error')
            msg = res.error;
        else
            % No answer at all: Python was killed, almost always for lack of
            % memory (the model needs ~4 GB of GPU or ~7 GB of RAM).
            msg = sprintf(['Python ended (status %d) without an answer - most likely out ' ...
                'of memory. Close other programs (a second MATLAB, browsers) and run ' ...
                'again. Command:\n%s'], status, cmd);
        end
        error('Project2:SynthesisFailed', 'KittenTTS failed: %s', strtrim(msg));
    end
    info.synthSec = res.synthSec;
end
[x, fs] = p2_load_audio(outWav, o.TargetFs);
info.file = outWav;
info.durationSec = numel(x) / fs;
end
