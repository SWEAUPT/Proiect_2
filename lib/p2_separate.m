function [Y, info] = p2_separate(mixFiles, model, varargin)
% P2_SEPARATE Separate mixtures with one of four speech-separation models.
%
%   [Y, info] = p2_separate(mixFiles, "sepformer", 'NumSpeakers', 2)
%   [Y, info] = p2_separate(mixFiles, "convtasnet")     % count unknown
%   [Y, info] = p2_separate(mixFiles, "mossformer2")    % 2 speakers only
%   [Y, info] = p2_separate(mixFiles, "tiger")          % 2 speakers only
%   ... 'OutDir', dir   where the separated WAVs are cached (default: next
%                       to the mixtures, in a "separated" folder)
%   ... 'Force', true   separate again even if the cached result exists
%
% mixFiles is a string array of WAV files. Y{i} is N-by-K (one column per
% extracted speaker) at the sample rate of mixFiles(i); info(i) holds the
% model, device and timing.
%
% The models:
%   convtasnet   MATLAB separateSpeakers, NumSpeakers omitted. Conv-TasNet,
%                "one-and-rest": one speaker is pulled out, the rest is fed
%                back in until it contains no more speech. It finds the
%                number of speakers itself. The residual is appended as the
%                last column - if the stopping rule fires too early, the last
%                speaker is still in there.
%   sepformer    MATLAB separateSpeakers, NumSpeakers = 2 or 3. SepFormer
%                trained on Libri2Mix / Libri3Mix.
%     Both MATLAB models run at 8 kHz; separateSpeakers resamples in and out.
%   mossformer2  MossFormer2_SS_16K (ClearerVoice-Studio), WSJ0-2mix, 16 kHz
%   tiger        TIGER (ICLR 2025), trained on reverberant + noisy EchoSet,
%                16 kHz
%     Both Python models go through separate_bridge.py in the project's .venv.
%
% LEVELS ARE MADE COMPARABLE. separateSpeakers rescales its outputs by
% default (ConserveEnergy): least-squares gains so that the outputs add up
% to the mixture. The Python models return an arbitrary scale, which would
% ruin the plain SNR for reasons that have nothing to do with separation.
% The same least-squares rule is applied to them here.
%
% GPU: used when one is available (gpuArray for MATLAB, CUDA in Python).
% Timing: info.separateSec is the separation alone. separateSpeakers loads
% its network inside every call, so for the MATLAB models info.loadSec is
% measured once (a call on one second of near-silence, after a warm-up
% call) and subtracted. That makes their times approximate.

p = inputParser;
p.addParameter('NumSpeakers', [], @(v) isempty(v) || ismember(v, [1 2 3]));
p.addParameter('OutDir', '', @(s) ischar(s) || isstring(s));
p.addParameter('Force', false, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;

% string() first: (:) on a char path would split it into single characters.
mixFiles = string(mixFiles);
mixFiles = mixFiles(:);
model = lower(string(model));
if ~ismember(model, ["convtasnet" "sepformer" "mossformer2" "tiger"])
    error('Project2:UnknownModel', 'Unknown model "%s".', model);
end
if model == "sepformer" && ~(isscalar(o.NumSpeakers) && ismember(o.NumSpeakers, [2 3]))
    error('Project2:SepFormerCount', 'SepFormer needs ''NumSpeakers'', 2 or 3.');
end
outDir = string(o.OutDir);
if outDir == "", outDir = fullfile(fileparts(mixFiles(1)), "separated"); end
if ~isfolder(outDir), mkdir(outDir); end

n = numel(mixFiles);
Y = cell(n, 1);
info = repmat(struct('model', model, 'device', "", 'separateSec', NaN, ...
    'loadSec', NaN, 'cached', false, 'files', strings(0, 1)), n, 1);
todo = false(n, 1);
for i = 1:n
    [~, stem] = fileparts(mixFiles(i));
    meta = fullfile(outDir, stem + "_" + model + ".json");
    if ~logical(o.Force) && isfile(meta) && dir(meta).datenum >= dir(mixFiles(i)).datenum
        m = jsondecode(fileread(meta));
        files = string(m.files);
        Y{i} = cell2mat(cellfun(@(f) audioread(f), cellstr(files(:)'), 'UniformOutput', false));
        info(i).device = string(m.device);
        info(i).separateSec = m.separateSec;
        info(i).loadSec = m.loadSec;
        info(i).cached = true;
        info(i).files = files;
    else
        todo(i) = true;
    end
end
if ~any(todo), return; end

idx = find(todo);
if ismember(model, ["convtasnet" "sepformer"])
    [Yn, sec, loadSec, dev] = run_matlab(mixFiles(idx), model, o.NumSpeakers);
else
    [Yn, sec, loadSec, dev] = run_python(mixFiles(idx), model, outDir);
end
for j = 1:numel(idx)
    i = idx(j);
    [x, fs] = audioread(mixFiles(i));
    y = Yn{j};
    if ismember(model, ["mossformer2" "tiger"])
        y = conserve_energy(x, y);
    end
    [~, stem] = fileparts(mixFiles(i));
    files = strings(size(y, 2), 1);
    for k = 1:size(y, 2)
        files(k) = fullfile(outDir, sprintf('%s_%s_y%d.wav', stem, model, k));
        audiowrite(files(k), y(:, k), fs, BitsPerSample = 32);
    end
    Y{i} = y;
    info(i).device = dev;
    info(i).separateSec = sec(j);
    info(i).loadSec = loadSec;
    info(i).files = files;
    m = struct('files', files, 'device', dev, 'separateSec', sec(j), 'loadSec', loadSec);
    writelines(jsonencode(m), fullfile(outDir, stem + "_" + model + ".json"));
end
end

% =====================================================================
function [Y, sec, loadSec, dev] = run_matlab(files, model, numSpeakers)
gpu = canUseGPU;
dev = "cpu"; if gpu, dev = "gpu"; end
args = {};
if model == "sepformer", args = {'NumSpeakers', numSpeakers}; end
    function y = sep(x, fs)
        x = single(x);
        if gpu, x = gpuArray(x); end
        if model == "convtasnet"
            [y, r] = separateSpeakers(x, fs);
            y = [y, r];
        else
            y = separateSpeakers(x, fs, args{:});
        end
        y = double(gather(y));
    end
% Load-time estimate: the network is built inside every call. The first
% call also warms up the GPU and is slower, so it is discarded.
quiet = 1e-4 * randn(8000, 1);
sep(quiet, 8000);
t0 = tic; sep(quiet, 8000); loadSec = toc(t0);
Y = cell(numel(files), 1);
sec = nan(numel(files), 1);
for k = 1:numel(files)
    [x, fs] = audioread(files(k));
    t0 = tic;
    Y{k} = sep(mean(x, 2), fs);
    sec(k) = max(toc(t0) - loadSec, 0);
end
end

function [Y, sec, loadSec, dev] = run_python(files, model, outDir)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
py = fullfile(projectRoot, '.venv', 'Scripts', 'python.exe');
if ~isfile(py)
    error('Project2:NoVenv', 'Project Python environment not found (%s). Run setup_tts.ps1.', py);
end
rawDir = fullfile(outDir, "raw");
cmd = sprintf('"%s" "%s" --model %s --outdir "%s" --mix%s', py, ...
    fullfile(projectRoot, 'separate_bridge.py'), model, rawDir, sprintf(' "%s"', files));
fprintf('Separating %d mixture(s) with %s...\n', numel(files), model);
[status, out] = system(cmd);
res = p2_bridge_json(out);
if status ~= 0 || isempty(res) || ~res.ok
    msg = out;
    if ~isempty(res) && isfield(res, 'error'), msg = res.error; end
    error('Project2:SeparationFailed', '%s failed: %s', model, strtrim(msg));
end
Y = cell(numel(files), 1);
f = res.files;                         % jsondecode: char matrix rows or cell
if ~iscell(f), f = num2cell(f, 2); end
for k = 1:numel(files)
    [~, fs] = audioread(files(k));
    fk = string(f{k});
    y = cell2mat(cellfun(@(p) audioread(p), cellstr(fk(:)'), 'UniformOutput', false));
    Y{k} = resample(y, fs, res.fs);
end
sec = res.separateSec(:);
loadSec = res.loadSec;
dev = string(res.device);
end

function y = conserve_energy(x, y)
% Same rule as separateSpeakers(ConserveEnergy=true): gains g minimising
% sum((x - y*g).^2), then rescaled only if a sample would exceed 1.
n = min(size(x, 1), size(y, 1));
x = mean(x(1:n, :), 2);
y = y(1:n, :);
g = y \ x;
y = y .* g';
y = y / max(max(abs(y(:))), 1);
end
