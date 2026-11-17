function texts = p2_transcribe(files, language)
% P2_TRANSCRIBE Speech to text with Whisper large-v3, through the bridge.
%
%   texts = p2_transcribe(["a.wav" "b.wav"], "en")
%   texts = p2_transcribe("c.wav", "ro")
%   texts = p2_transcribe(files, "")       % Whisper detects the language
%
% MATLAB's own speech2text offers Whisper and wav2vec 2.0 only after a
% support-file download, and its emformer model is English-only. The project's
% Python environment already holds Whisper large-v3 (KittenTTS uses it),
% which knows Romanian, so this goes through kitten_bridge.py instead.
%
% Every transcript is CACHED next to its WAV as <name>.<language>.txt and
% reused while it is newer than the WAV. All files that still need work go
% to Python in ONE call, because loading Whisper takes longer than using it.

% string() first: (:) on a char path would split it into single characters.
files = string(files);
files = files(:);
language = string(language);
tag = language; if tag == "", tag = "auto"; end
texts = strings(numel(files), 1);
cache = files + "." + tag + ".txt";
todo = false(numel(files), 1);
for k = 1:numel(files)
    if ~isfile(files(k)), error('Project2:NoFile', 'Audio file not found: %s', files(k)); end
    w = dir(files(k)); c = dir(cache(k));
    if ~isempty(c) && c.datenum >= w.datenum
        texts(k) = strtrim(string(fileread(cache(k), Encoding = "UTF-8")));
    else
        todo(k) = true;
    end
end
if ~any(todo), return; end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
py = fullfile(projectRoot, '.venv', 'Scripts', 'python.exe');
if ~isfile(py)
    error('Project2:NoVenv', 'Project Python environment not found (%s). Run setup_tts.ps1.', py);
end
args = sprintf(' "%s"', files(todo));
if language ~= "", args = sprintf('%s --language %s', args, language); end
cmd = sprintf('"%s" "%s" transcribe --audio%s', py, fullfile(projectRoot, 'kitten_bridge.py'), args);
fprintf('Transcribing %d file(s) with Whisper (%s)...\n', nnz(todo), tag);
[status, out] = system(cmd);
res = p2_bridge_json(out);
if status ~= 0 || isempty(res) || ~res.ok
    msg = out;
    if ~isempty(res) && isfield(res, 'error'), msg = res.error; end
    error('Project2:TranscribeFailed', 'Whisper failed: %s', strtrim(msg));
end
idx = find(todo);
got = string(res.texts);
for j = 1:numel(idx)
    texts(idx(j)) = got(j);
    writelines(got(j), cache(idx(j)), Encoding = "UTF-8");
end
end
