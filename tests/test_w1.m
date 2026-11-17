function tests = test_w1
% Week 1 tests: loading audio, quality report, reference voice.
tests = functiontests(localfunctions);
end

function testLoadAudioMonoNoDcResampled(testCase)
d = p2_test_helpers.tempDir(testCase);
fs = 44100;
t = (0:fs - 1)' / fs;
st = [0.5 * sin(2 * pi * 200 * t) + 0.1, 0.3 * sin(2 * pi * 300 * t) + 0.1];   % stereo + DC
f = fullfile(d, 'stereo.wav');
audiowrite(f, st, fs);
[x, fsOut, info] = p2_load_audio(f, 24000);
verifyEqual(testCase, fsOut, 24000);
verifySize(testCase, x, [24000 1], 'One second at 24 kHz, mono, as a column.');
verifyLessThan(testCase, abs(mean(x)), 1e-3, 'The DC offset must be removed.');
verifyEqual(testCase, info.channels, 2);
verifyEqual(testCase, info.fsOriginal, fs);
end

function testLoadAudioMissingFile(testCase)
verifyError(testCase, @() p2_load_audio('no_such_file_here.wav'), 'Project2:NoFile');
end

function testQualityReportFlagsClipping(testCase)
fs = 16000;
x = p2_test_helpers.voiced(150, fs, 3);
clean = p2_quality_report(x, fs);
clipped = p2_quality_report(min(max(20 * x, -1), 1), fs);
row = @(T) T(T.Check == "Clipped samples (%)", :);
verifyEqual(testCase, row(clean).Status, "OK");
verifyEqual(testCase, row(clipped).Status, "WARN", 'Heavy clipping must be flagged.');
end

function testReferenceSampleContract(testCase)
assumeNotEmpty(testCase, which('Counting-16-44p1-mono-15secs.wav'), ...
    'The Audio Toolbox sample recording is not on the path.');
ref = w1_reference_voice('Plot', false, 'Play', false);
verifyEqual(testCase, ref.fs, 24000);
verifyTrue(testCase, iscolumn(ref.x));
verifyGreaterThan(testCase, numel(ref.x) / ref.fs, 10, 'The sample lasts about 15 s.');
verifyTrue(testCase, istable(ref.quality));
verifyEqual(testCase, string(ref.quality.Properties.VariableNames), ["Check" "Value" "Target" "Status"]);
end

function testWindowTradeoffFigure(testCase)
fs = 16000;
fig = p2_plot_window_tradeoff(p2_test_helpers.voiced(120, fs, 1), fs, [5 25 100]);
testCase.addTeardown(@() close(fig));
verifyEqual(testCase, numel(findobj(fig, 'Type', 'axes')), 3, 'One panel per window length.');
end
