classdef p2_test_helpers
% P2_TEST_HELPERS Shared helpers for the test suites (synthetic signals).

    methods (Static)
        function x = voiced(f0, fs, sec)
            % A harmonic "vowel" at pitch f0 with a slight vibrato, between
            % two stretches of near-silence: pitch trackers and the voicing
            % rule of p2_voice_profile need both speech and a noise floor.
            t = (0:round(sec * fs) - 1)' / fs;
            ph = 2 * pi * cumsum(f0 * (1 + 0.01 * sin(2 * pi * 5 * t))) / fs;
            v = zeros(size(t));
            for h = 1:20
                if h * f0 < fs / 2, v = v + sin(h * ph) / h; end
            end
            v = 0.3 * v / max(abs(v)) .* tukeywin(numel(t), 0.1);
            gap = zeros(round(0.5 * fs), 1);
            rng(1);
            x = [gap; v; gap] + 1e-4 * randn(numel(v) + 2 * numel(gap), 1);
        end

        function slow = slowTests()
            slow = getenv("P2_SLOW_TESTS") == "1";
        end

        function d = tempDir(testCase)
            fx = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            d = fx.Folder;
        end
    end
end
