function tests = test_w4
% Week 4 tests: mixing and the speaker table.
tests = functiontests(localfunctions);
end

function testMixtureIsSumOfSources(testCase)
rng(2);
[m, S] = p2_mix({randn(1000, 1), randn(1500, 1)});
verifySize(testCase, S, [1500 2], 'Padded to the longest source.');
verifyEqual(testCase, m, sum(S, 2), 'AbsTol', 1e-12, 'mix == sum(S, 2) must hold exactly.');
verifyEqual(testCase, max(abs(m)), 0.9, 'AbsTol', 1e-12, 'Peak-normalised to 0.9.');
verifyEqual(testCase, S(1001:end, 1), zeros(500, 1), 'The shorter source is padded with silence.');
end

function testMixtureLevels(testCase)
rng(3);
[~, S] = p2_mix({randn(4000, 1), randn(4000, 1)}, [0 -6]);
verifyEqual(testCase, 20 * log10(rms(S(:, 2)) / rms(S(:, 1))), -6, 'AbsTol', 1e-9);
end

function testMixtureLevelCountMismatch(testCase)
verifyError(testCase, @() p2_mix({ones(10, 1), ones(10, 1)}, 0), 'Project2:MixLevels');
end

function testSilentSourceIsAnError(testCase)
% rms 0 would turn the whole mixture into NaN.
verifyError(testCase, @() p2_mix({randn(100, 1), zeros(100, 1)}), 'Project2:SilentSource');
end

function testGenderRule(testCase)
verifyEqual(testCase, p2_gender_from_f0([127 187.1 165 NaN]), ["m" "f" "m" "?"]);
end

function testWriteIfChangedSkipsIdenticalAudio(testCase)
d = p2_test_helpers.tempDir(testCase);
f = fullfile(d, 'mix.wav');
x = 0.5 * sin((1:8000)' / 10);
verifyTrue(testCase, p2_write_if_changed(f, x, 16000), 'First write.');
verifyFalse(testCase, p2_write_if_changed(f, x, 16000), 'Same samples: no rewrite.');
verifyTrue(testCase, p2_write_if_changed(f, 0.9 * x, 16000), 'Changed samples: rewrite.');
end

function testMixturesFromCachedSpeakers(testCase)
% Uses the synthesised speakers if they are cached (after one main run).
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root, 'audio', 'sep', 'sources');
assumeTrue(testCase, all(isfile(fullfile(src, ["en_m1" "en_f1" "en_m2" "ro_m" "ro_f"] + ".wav"))), ...
    'Speakers not cached yet - run main up to Week 4 first.');
d = p2_test_helpers.tempDir(testCase);
copyfile(src, fullfile(d, 'sources'));
[spk, x, mixes] = w4_make_mixtures('AudioDir', d, 'Plot', false, 'Play', false);
verifyEqual(testCase, numel(x), height(spk));
verifyEqual(testCase, spk.MeasuredGender, spk.Gender, 'Every voice must be the intended gender.');
for i = 1:numel(mixes)
    verifyEqual(testCase, mixes(i).x, sum(mixes(i).S, 2), 'AbsTol', 1e-12);
    verifyTrue(testCase, isfile(mixes(i).file));
end
end
