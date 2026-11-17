function results = run_all_tests(varargin)
% RUN_ALL_TESTS Full test suite of Project 2.
%
%   results = run_all_tests()
%   results = run_all_tests('Week', 5)      % only the Week 5 tests
%
% Fast tests use synthetic signals and need only MATLAB. Tests that need
% the MATLAB separation models are skipped if models/separateSpeakers is
% missing. Tests that synthesise speech, run Whisper or the Python
% separators take minutes and run only when the environment variable
% P2_SLOW_TESTS is "1":
%   setenv("P2_SLOW_TESTS", "1"); run_all_tests
% Skipped tests are reported as skipped, not as passed.

p = inputParser;
p.addParameter('Week', [], @(x) isempty(x) || isnumeric(x));
p.parse(varargin{:});
week = p.Results.Week;

root = fileparts(mfilename('fullpath'));
testDir = fullfile(root, 'tests');
addpath(root, fullfile(root, 'lib'), testDir);
addpath(genpath(fullfile(root, 'models', 'separateSpeakers')));
global PROJECT2_PLAY %#ok<GVMIS>
PROJECT2_PLAY = false;               % tests never play sound

fprintf('\n========================================================\n');
fprintf('   AUTOMATED TESTS - PROJECT 2 (WEEKS 1-7)\n');
fprintf('   Slow tests: %s\n', ternary(getenv("P2_SLOW_TESTS") == "1", "ON", "off (set P2_SLOW_TESTS=1)"));
fprintf('========================================================\n\n');

if isempty(week)
    files = dir(fullfile(testDir, 'test_w*.m'));
    [~, ord] = sort({files.name});
    suitePaths = fullfile(testDir, {files(ord).name});
else
    suitePaths = {fullfile(testDir, sprintf('test_w%d.m', week))};
    if ~isfile(suitePaths{1})
        error('Project2:NoSuchSuite', 'There is no %s', suitePaths{1});
    end
end

allResults = [];
loadErrors = {};
for i = 1:numel(suitePaths)
    [~, name] = fileparts(suitePaths{i});
    fprintf('[%s] ', name);
    try
        r = runtests(suitePaths{i});
        allResults = [allResults, r]; %#ok<AGROW>
        nPass = sum([r.Passed]); nFail = sum([r.Failed]);
        nInc = sum([r.Incomplete]); nTot = numel(r);
        % A failure is reported before "skipped", so it is never hidden.
        if nFail > 0
            fprintf('FAILED (%d passed, %d failed, %d skipped of %d)\n', nPass, nFail, nInc, nTot);
        elseif nInc > 0
            fprintf('%d/%d passed, %d skipped\n', nPass, nTot, nInc);
        else
            fprintf('OK (%d/%d)\n', nPass, nTot);
        end
    catch ME
        % A suite that does not LOAD produces no TestResult and would be
        % missing from the totals; count it explicitly instead.
        loadErrors{end + 1} = sprintf('%s: %s', name, regexprep(ME.message, '[\r\n]+', ' ')); %#ok<AGROW>
        fprintf('LOAD ERROR: %s\n', ME.message);
    end
end

if isempty(allResults)
    warning('Project2:NoTestsRan', 'No test ran.');
    results = struct('passed', 0, 'failed', 0, 'incomplete', 0, 'total', 0, ...
        'percent', NaN, 'loadErrors', {loadErrors}, 'details', []);
    return
end

passed = sum([allResults.Passed]);
failed = sum([allResults.Failed]);
incomplete = sum([allResults.Incomplete]);
total = numel(allResults);
pct = 100 * passed / max(total, 1);

fprintf('\n--------------------------------------------------------\n');
fprintf('RESULT: %d passed, %d failed, %d skipped of %d (%.1f%%)\n', ...
    passed, failed, incomplete, total, pct);
fprintf('Total time: %.1f s\n', sum([allResults.Duration]));
fprintf('--------------------------------------------------------\n\n');

if ~isempty(loadErrors)
    fprintf('Suites that did NOT load (their tests are not in the totals above):\n');
    fprintf('  - %s\n', loadErrors{:});
    fprintf('\n');
end
if failed > 0
    fprintf('Failed tests:\n');
    for r = allResults([allResults.Failed])
        fprintf('  - %s\n', r.Name);
    end
    fprintf('\n');
    warning('Project2:TestsFailed', '%d tests failed.', failed);
end
if ~isempty(loadErrors)
    warning('Project2:SuiteLoadFailed', ['%d test suites could not be loaded and did ' ...
        'not run. The result above does NOT cover the whole project.'], numel(loadErrors));
elseif failed == 0 && incomplete > 0
    fprintf('All tests that ran passed; %d were skipped (slow tests or missing models).\n\n', incomplete);
elseif failed == 0
    fprintf('All tests passed.\n\n');
end

results = struct('passed', passed, 'failed', failed, 'incomplete', incomplete, ...
    'total', total, 'percent', pct, 'loadErrors', {loadErrors}, 'details', allResults);
end

% =====================================================================
function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
