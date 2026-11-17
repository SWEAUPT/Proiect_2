function tests = test_w2
% Week 2 tests: voice fingerprint.
tests = functiontests(localfunctions);
end

function testPitchOfSyntheticMaleVoice(testCase)
fs = 16000;
P = p2_voice_profile(p2_test_helpers.voiced(120, fs, 2), fs, "synthetic");
verifyEqual(testCase, P.f0Median, 120, 'AbsTol', 3, 'Median F0 of a 120 Hz voice.');
verifyGreaterThan(testCase, P.voicedShare, 0.3);
verifyLessThan(testCase, P.voicedShare, 0.9, 'The silent gaps must not count as voiced.');
end

function testPitchOfSyntheticFemaleVoice(testCase)
fs = 16000;
P = p2_voice_profile(p2_test_helpers.voiced(220, fs, 2), fs, "synthetic");
verifyEqual(testCase, P.f0Median, 220, 'AbsTol', 5);
verifyGreaterThan(testCase, P.f0Median, 165, 'Above the female/male boundary.');
end

function testFingerprintTable(testCase)
fs = 16000;
[P, T, fig] = w2_voice_fingerprint(p2_test_helpers.voiced(130, fs, 2), fs, "x", 'Plot', false);
verifyEqual(testCase, height(T), 1);
verifyEqual(testCase, T.MedianF0_Hz, round(P.f0Median, 1));
verifyEmpty(testCase, fig);
end
