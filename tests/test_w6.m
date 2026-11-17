function tests = test_w6
% Week 6 tests: the transcript cache and Whisper (WER itself is tested in Week 3).
tests = functiontests(localfunctions);
end

function testTranscriptCacheNeedsNoPython(testCase)
d = p2_test_helpers.tempDir(testCase);
f = fullfile(d, 'a.wav');
audiowrite(f, zeros(1600, 1), 16000);
pause(1.1);                                 % cache must be NEWER than the WAV
writelines("Astăzi este o zi frumoasă", f + ".ro.txt", Encoding = "UTF-8");
verifyEqual(testCase, p2_transcribe(f, "ro"), "Astăzi este o zi frumoasă", ...
    'Cached UTF-8 text, diacritics intact.');
end

function testTranscribeMissingFile(testCase)
verifyError(testCase, @() p2_transcribe("no_such.wav", "en"), 'Project2:NoFile');
end

function testWhisperRoundTrip(testCase)
assumeTrue(testCase, p2_test_helpers.slowTests(), 'Slow test: set P2_SLOW_TESTS=1.');
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root, 'audio', 'sep', 'sources', 'en_m1.wav');
assumeTrue(testCase, isfile(src), 'Speaker en_m1 not cached yet.');
d = p2_test_helpers.tempDir(testCase);
copyfile(src, d);
hyp = p2_transcribe(fullfile(d, 'en_m1.wav'), "en");
verifyLessThan(testCase, p2_wer("The weather station recorded heavy rain over the mountains this morning.", hyp), 0.2);
end
