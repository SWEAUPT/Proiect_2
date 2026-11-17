function tests = test_w3
% Week 3 tests: the KittenTTS bridge, cloning, voice distances, word error rate.
tests = functiontests(localfunctions);
end

function testCachedSynthesisNeedsNoPython(testCase)
% A file that already exists is loaded, never re-synthesised: re-running a
% week must not cost minutes of GPU time.
d = p2_test_helpers.tempDir(testCase);
f = fullfile(d, 'cached.wav');
audiowrite(f, 0.1 * sin(2 * pi * 200 * (0:23999)' / 24000), 24000);
[x, fs, info] = p2_kitten_tts("anything", f);
verifyTrue(testCase, info.cached);
verifyEqual(testCase, fs, 24000);
verifyEqual(testCase, numel(x), 24000);
end

function testBridgeJsonTakesLastJsonLine(testCase)
out = sprintf('loading model...\n{"ok": false}\nmore log\n{"ok": true, "fs": 24000}\n');
r = p2_bridge_json(out);
verifyTrue(testCase, r.ok);
verifyEqual(testCase, r.fs, 24000);
verifyEmpty(testCase, p2_bridge_json(sprintf('no json here\n')));
end

function testMissingReferenceIsAnError(testCase)
d = p2_test_helpers.tempDir(testCase);
root = fileparts(fileparts(mfilename('fullpath')));
assumeTrue(testCase, isfile(fullfile(root, '.venv', 'Scripts', 'python.exe')), 'No .venv.');
verifyError(testCase, @() p2_kitten_tts("x", fullfile(d, 'o.wav'), ...
    'Reference', fullfile(d, 'missing.wav')), 'Project2:NoReference');
end

function testProfileAgainstItselfIsZero(testCase)
fs = 16000;
P = p2_voice_profile(p2_test_helpers.voiced(140, fs, 2), fs, "a");
T = p2_compare_profiles(P, P);
v = T{1, 2:end};
verifyEqual(testCase, v, zeros(size(v)), 'AbsTol', 1e-9, 'A voice is at distance 0 from itself.');
end

function testDifferentPitchIsFarther(testCase)
fs = 16000;
P = p2_voice_profile(p2_test_helpers.voiced(120, fs, 2), fs, "ref");
Q = p2_voice_profile(p2_test_helpers.voiced(240, fs, 2), fs, "octave up");
T = p2_compare_profiles(P, Q);
verifyEqual(testCase, T.dF0_st, 12, 'AbsTol', 0.5, 'One octave is 12 semitones.');
end

function testIdenticalTextIsZero(testCase)
verifyEqual(testCase, p2_wer("The cat sat.", "the CAT sat"), 0, 'Case and punctuation are ignored.');
end

function testOneSubstitution(testCase)
[w, nErr, nRef] = p2_wer("the cat sat on the mat", "the dog sat on the mat");
verifyEqual(testCase, [nErr nRef], [1 6]);
verifyEqual(testCase, w, 1 / 6, 'AbsTol', 1e-12);
end

function testDeletionAndInsertion(testCase)
verifyEqual(testCase, p2_wer("a b c d", "a c d"), 0.25);
verifyEqual(testCase, p2_wer("a b", "a b c d e"), 1.5, 'Insertions can push WER above 1.');
end

function testRomanianDiacriticsVariants(testCase)
% s/t with comma below and with cedilla are the same letter.
verifyEqual(testCase, p2_wer("Studenții și pregătesc", "Studenţii şi pregătesc"), 0);
% A missing diacritic IS a different word.
verifyEqual(testCase, p2_wer("frumoasă", "frumoasa"), 1);
end

function testWordsAreNotErased(testCase)
% Letters must survive the text cleanup: MATLAB regexp has no \p{L} class,
% and a pattern relying on it would erase every word.
verifyEqual(testCase, p2_wer("one two three four", "one two three five"), 0.25);
end

function testCloneDoesNotRepeatItself(testCase)
% Slow: synthesises with KittenTTS 2. A clone that repeats itself lasts far
% longer than the sentence needs.
assumeTrue(testCase, p2_test_helpers.slowTests(), 'Slow test: set P2_SLOW_TESTS=1.');
d = p2_test_helpers.tempDir(testCase);
ref = w1_reference_voice('Plot', false, 'Play', false);
P = p2_voice_profile(ref.x, ref.fs, "reference");
C = w3_clone_voice(ref, P, 'AudioDir', d, 'Plot', false, 'Play', false);
verifyLessThan(testCase, numel(C.signals.clone) / ref.fs, 12, ...
    'Ten digits take a few seconds; much longer means the clone repeats itself.');
verifyLessThan(testCase, C.werRo, 0.5, 'Whisper should understand most of the Romanian clone.');
end
