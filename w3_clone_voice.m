function C = w3_clone_voice(ref, refProfile, varargin)
% W3_CLONE_VOICE Week 3: KittenTTS 2 - built-in voices, a clone, Romanian.
%
%   C = w3_clone_voice(ref, refProfile)
%   ... 'VoiceA', "Bruno", 'VoiceB', "Luna"   unrelated built-in voices
%   ... 'TextEn', "...", 'TextRo', "...", 'ReferenceText', "..."
%   ... 'Seed', 7, 'AudioDir', "audio", 'Plot', true, 'Play', true
%
% C.signals     struct: clone, voiceA, voiceB, cloneRo (column vectors, ref.fs)
% C.profiles    struct of p2_voice_profile results
% C.comparison  distance of every voice from the reference (table)
% C.acrossLanguages  reference vs English clone vs Romanian clone
% C.transcriptRo, C.werRo   Whisper on the Romanian clone
%
% WHAT THIS WEEK IS ABOUT
%   KittenTTS 2 (KittenML/kitten-tts-2, 1.7 B parameters) reads text and
%   writes audio codec tokens that a decoder turns into 24 kHz speech. It
%   clones a voice "in context" from 5-30 s of one speaker.
%   1. Two BUILT-IN voices are the baseline: they were never meant to sound
%      like the reference. A clone is good only if it sits clearly closer
%      to the reference than they do - a distance means nothing alone.
%   2. The clone and both built-in voices say the SAME sentence, because
%      formants and spectra depend on the vowels spoken. The reference says
%      something else (it counts) - but equally for all three, so the
%      comparison between them stays fair.
%   3. Romanian is not one of the model's listed languages. What breaks
%      first - the voice identity or the pronunciation? Listen for s-comma
%      (sase, sapte: "sh"?), a-breve (noua: /schwa/?) and the stress.
%
% WHY NOT THE REFERENCE'S OWN WORDS
%   The reference counts "one ... ten". Asked to say exactly that, the clone
%   did not stop ("one ... eight, one ... ten", 27 s); asked to count
%   backwards, it broke off and started again ("ten ... seven, ten, nine").
%   An ordinary sentence came out right first time. A clone can fail on
%   material that resembles its reference - always listen to it.
%
% 'ReferenceText' is what the reference says. Without it KittenTTS runs
% Whisper on the reference itself - in ENGLISH, so for a Romanian reference
% it must be given.

p = inputParser;
p.addParameter('VoiceA', "Bruno", @(s) ischar(s) || isstring(s));
p.addParameter('VoiceB', "Luna", @(s) ischar(s) || isstring(s));
p.addParameter('TextEn', "The weather station recorded heavy rain over the mountains this morning.", ...
    @(s) ischar(s) || isstring(s));
p.addParameter('TextRo', "Unu, doi, trei, patru, cinci, șase, șapte, opt, nouă, zece.", ...
    @(s) ischar(s) || isstring(s));
% Whisper writes counted numbers as DIGITS ("1, 2, 3"), so the transcript is
% also scored against this spelling and the better match is kept.
p.addParameter('TextRoDigits', "1, 2, 3, 4, 5, 6, 7, 8, 9, 10", @(s) ischar(s) || isstring(s));
p.addParameter('ReferenceText', "One, two, three, four, five, six, seven, eight, nine, ten.", ...
    @(s) ischar(s) || isstring(s));
p.addParameter('Seed', 7, @(v) isnumeric(v) && isscalar(v));
p.addParameter('AudioDir', fullfile(fileparts(mfilename('fullpath')), 'audio'), ...
    @(s) ischar(s) || isstring(s));
p.addParameter('Plot', true, @(b) islogical(b) || isnumeric(b));
p.addParameter('Play', true, @(b) islogical(b) || isnumeric(b));
p.parse(varargin{:});
o = p.Results;
FS = ref.fs;
d = char(o.AudioDir);
if ~isfolder(d), mkdir(d); end
refFile = char(ref.file);
common = {'Seed', o.Seed, 'TargetFs', FS};
cloneOpts = [common, {'Reference', refFile, 'ReferenceText', o.ReferenceText}];

fprintf('[W3] Synthesis with KittenTTS 2 (cached in %s)...\n', d);
s.voiceA = p2_kitten_tts(o.TextEn, fullfile(d, 'w3_builtin_A_en.wav'), common{:}, 'Voice', o.VoiceA);
s.voiceB = p2_kitten_tts(o.TextEn, fullfile(d, 'w3_builtin_B_en.wav'), common{:}, 'Voice', o.VoiceB);
s.clone  = p2_kitten_tts(o.TextEn, fullfile(d, 'w3_clone_en.wav'), cloneOpts{:});
% The English text normaliser would rewrite Romanian text.
s.cloneRo = p2_kitten_tts(o.TextRo, fullfile(d, 'w3_clone_ro.wav'), cloneOpts{:}, 'Normalize', false);
C.signals = s;

if logical(o.Play)
    p2_listen(ref.x, FS, 'reference');
    p2_listen(s.clone, FS, 'clone');
    p2_listen(s.voiceA, FS, "built-in " + o.VoiceA);
    p2_listen(s.cloneRo, FS, 'clone speaking Romanian');
end

P.ref = refProfile;
P.clone = p2_voice_profile(s.clone, FS, "clone");
P.voiceA = p2_voice_profile(s.voiceA, FS, "built-in " + o.VoiceA);
P.voiceB = p2_voice_profile(s.voiceB, FS, "built-in " + o.VoiceB);
P.cloneRo = p2_voice_profile(s.cloneRo, FS, "clone (Romanian)");
C.profiles = P;

% Every column is a DISTANCE from the reference: 0 = identical.
C.comparison = p2_compare_profiles(P.ref, P.clone, P.voiceA, P.voiceB);
C.acrossLanguages = p2_compare_profiles(P.ref, P.clone, P.cloneRo);
fprintf('[W3] Distance from the reference (clone vs unrelated voices):\n');
disp(C.comparison);
fprintf('[W3] Same clone, English vs Romanian:\n');
disp(C.acrossLanguages);
dur = numel(s.clone) / FS;
if dur > 3 * numel(ref.x) / FS / 2
    warning('Project2:CloneTooLong', ['The English clone lasts %.1f s for %.1f s of ' ...
        'reference - it may be repeating itself. Listen to it.'], dur, numel(ref.x) / FS);
end

% Intelligibility check: does Whisper understand the Romanian clone?
C.transcriptRo = p2_transcribe(fullfile(d, 'w3_clone_ro.wav'), "ro");
C.werRo = min(p2_wer(o.TextRo, C.transcriptRo), p2_wer(o.TextRoDigits, C.transcriptRo));
fprintf('[W3] Romanian clone heard as: "%s" (WER %.2f)\n', C.transcriptRo, C.werRo);

C.figures = gobjects(0);
if logical(o.Plot)
    C.figures = p2_plot_voices({ref.x, s.clone, s.voiceA}, FS, ...
        ["reference", "clone", "built-in " + o.VoiceA], {P.ref, P.clone, P.voiceA});
end
end
