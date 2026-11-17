function tests = test_w7
% Week 7 tests: dashboard, saving results, recordings switched off.
tests = functiontests(localfunctions);
end

function [snri, wer, sweep, clone] = fakeResults()
mixtures = ["A"; "B"; "E"];
snri = table(mixtures, [15; 9; 9], [23; 19; NaN], [24; 3; 20], ...
    'VariableNames', {'Mixture', 'convtasnet', 'mossformer2', 'sepformer'});
wer = table(mixtures, [0; 0.1; 0.2], [0; 0; NaN], [0; 0.5; 0], ...
    'VariableNames', {'Mixture', 'convtasnet', 'mossformer2', 'sepformer'});
sweep = array2table([21 29; 15 23; 10 18], 'VariableNames', {'convtasnet', 'sepformer'}, ...
    'RowNames', {'-12 dB', '+0 dB', '+12 dB'});
clone = table(["clone"; "built-in Bruno"], [0.5; 3], [2; 10], [3; 12], [1; 4], [5; 20], ...
    'VariableNames', {'Voice', 'dF0_st', 'dF1_pct', 'dF2_pct', 'ltasRms_dB', 'mfccDist'});
end

function testDashboardHasFourPanels(testCase)
[snri, wer, sweep, clone] = fakeResults();
fig = w7_dashboard(snri, wer, sweep, 'CloneComparison', clone);
testCase.addTeardown(@() close(fig));
ax = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, numel(ax), 4);
% Every non-missing heat-map cell carries its number.
labels = string(get(findobj(fig, 'Type', 'text'), 'String'));
verifyTrue(testCase, any(labels == "23.0") && any(labels == "0.50"));
verifyFalse(testCase, any(labels == "NaN"), 'Missing cells stay blank.');
end

function testDashboardWithoutCloneComparison(testCase)
[snri, wer, sweep] = fakeResults();
fig = w7_dashboard(snri, wer, sweep);
testCase.addTeardown(@() close(fig));
verifyNotEmpty(testCase, findobj(fig, 'Type', 'text', 'String', 'Week 3 clone comparison not given'));
end

function testSaveResultWritesCsvAndPng(testCase)
d = p2_test_helpers.tempDir(testCase);
[~, ~, sweep] = fakeResults();
f1 = p2_save_result(d, "sweep", sweep);
verifyTrue(testCase, isfile(f1));
back = readtable(f1, 'ReadRowNames', true);
verifyEqual(testCase, back.Properties.RowNames, sweep.Properties.RowNames, 'Row names are kept.');

figs = [figure('Visible', 'off'), figure('Visible', 'off')];
testCase.addTeardown(@() close(figs));
f2 = p2_save_result(d, "figs", figs);
verifyEqual(testCase, numel(f2), 2);
verifyTrue(testCase, all(isfile(f2)));
end

function testRecordingsOffReturnEmptyTable(testCase)
spk = table(["a"; "b"], ["en"; "en"], ["x"; "y"], 'VariableNames', {'Id', 'Lang', 'Text'});
T = w7_real_recordings(spk, {zeros(10, 1), zeros(10, 1)}, 'Plot', false, 'Play', false);
verifyEqual(testCase, height(T), 0);
verifyEqual(testCase, string(T.Properties.VariableNames), ...
    ["Recording" "Model" "Output" "BestWER" "Transcript"]);
end
