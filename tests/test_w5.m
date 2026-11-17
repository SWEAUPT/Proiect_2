function tests = test_w5
% Week 5 tests: SNR, output pairing, permutation check, separation models.
tests = functiontests(localfunctions);
end

function testSnrFormula(testCase)
% s_r = 0.9 s: error energy is 1% of the signal energy -> exactly 20 dB.
% SI-SNR ignores the gain, so it is (numerically) infinite.
s = sin((1:1000)' / 7);
T = p2_separation_snr(s, 0.9 * s);
verifyEqual(testCase, T.SNR_dB, 20, 'AbsTol', 0.01);
verifyGreaterThan(testCase, T.SISNR_dB, 100);
end

function testOutputsArePairedWithTheRightSource(testCase)
% The model may return the speakers in any order.
rng(4);
S = randn(4000, 2);
Y = S(:, [2 1]) + 0.01 * randn(4000, 2);
[T, Ym, outIdx] = p2_separation_snr(S, Y, ["a" "b"]);
verifyEqual(testCase, outIdx, [2 1]);
verifyEqual(testCase, Ym, Y(:, [2 1]));
verifyGreaterThan(testCase, T.SNR_dB, [35; 35]);
end

function testInputSnrOfTwoEqualSpeakersIsZero(testCase)
rng(5);
S = randn(8000, 2);
S = S ./ rms(S);
T = p2_separation_snr(S, S);
verifyEqual(testCase, T.SNRin_dB, [0; 0], 'AbsTol', 0.2);
end

function testFewerOutputsThanSources(testCase)
rng(6);
S = randn(2000, 2);
T = p2_separation_snr(S, S(:, 1));
verifyEqual(testCase, sum(isnan(T.SNR_dB)), 1, 'An unmatched source has no SNR.');
verifyEqual(testCase, T.Output(isnan(T.SNR_dB)), 0);
end

function testSilentSourceStillPaired(testCase)
% A silent source has SNR -inf against every output; the other source must
% still get its own output instead of every source being left unmatched.
rng(8);
s = randn(2000, 1);
S = [s, zeros(2000, 1)];
[T, ~, outIdx] = p2_separation_snr(S, [0.01 * randn(2000, 1), s]);
verifyEqual(testCase, outIdx(1), 2);
verifyGreaterThan(testCase, T.SNR_dB(1), 100);
end

function testPermutationPlotShowsASwitch(testCase)
% Output 1 carries source 1 for the first half, then source 2.
fs = 8000;
rng(7);
S = randn(4 * fs, 2);
h = 2 * fs;
Y = [S(1:h, 1), S(1:h, 2); S(h + 1:end, 2), S(h + 1:end, 1)];
[fig, R] = p2_plot_permutation(S, Y, fs, ["a" "b"], "swap", 0.5);
testCase.addTeardown(@() close(fig));
verifyGreaterThan(testCase, R(1, 1, 1), 0.99, 'Start: output 1 = source a.');
verifyGreaterThan(testCase, R(2, 1, end), 0.99, 'End: output 1 = source b.');
verifyLessThan(testCase, R(1, 1, end), 0.1);
end

function testUnknownModelAndSepFormerCount(testCase)
verifyError(testCase, @() p2_separate("x.wav", "nosuchmodel"), 'Project2:UnknownModel');
verifyError(testCase, @() p2_separate("x.wav", "sepformer"), 'Project2:SepFormerCount');
end

function testMatlabModelsContract(testCase)
% Needs the MATLAB model files (setup_separation.ps1); ~1 minute.
assumeNotEmpty(testCase, which('sepformer-libri2mix-upit.mat'), ...
    'MATLAB separation models not installed (setup_separation.ps1).');
d = p2_test_helpers.tempDir(testCase);
fs = 16000;
a = p2_test_helpers.voiced(110, fs, 2);
b = p2_test_helpers.voiced(210, fs, 2);
f = fullfile(d, 'mix.wav');
audiowrite(f, 0.45 * (a + b) / max(abs(a + b)), fs, BitsPerSample = 32);

[Y, info] = p2_separate(f, "sepformer", 'NumSpeakers', 2, 'OutDir', d);
verifySize(testCase, Y{1}, [numel(a) 2]);
verifyTrue(testCase, all(isfile(info.files)));
verifyFalse(testCase, info.cached);

[~, info2] = p2_separate(f, "sepformer", 'NumSpeakers', 2, 'OutDir', d);
verifyTrue(testCase, info2.cached, 'The second call must come from the cache.');

Yc = p2_separate(f, "convtasnet", 'OutDir', d);
verifyGreaterThanOrEqual(testCase, size(Yc{1}, 2), 2, 'Conv-TasNet: speakers + residual.');
end

function testPythonModelsContract(testCase)
assumeTrue(testCase, p2_test_helpers.slowTests(), 'Slow test: set P2_SLOW_TESTS=1.');
d = p2_test_helpers.tempDir(testCase);
fs = 16000;
a = p2_test_helpers.voiced(110, fs, 2);
b = p2_test_helpers.voiced(210, fs, 2);
f = fullfile(d, 'mix.wav');
audiowrite(f, 0.45 * (a + b) / max(abs(a + b)), fs, BitsPerSample = 32);
for mdl = ["mossformer2" "tiger"]
    [Y, info] = p2_separate(f, mdl, 'OutDir', d);
    verifySize(testCase, Y{1}, [numel(a) 2], mdl);
    % Least-squares gains: the outputs add up to (nearly) the mixture.
    x = audioread(f);
    verifyLessThan(testCase, rms(x - sum(Y{1}, 2)) / rms(x), 0.5, mdl);
    verifyTrue(testCase, ismember(info.device, ["cuda" "cpu"]));
end
end
