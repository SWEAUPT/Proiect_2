"""Bridge between MATLAB and KittenTTS 2 (KittenML/kitten-tts-2).

MATLAB calls this script with system(); it never imports Python into MATLAB,
so MATLAB's own Python version (pyenv) does not matter. Only the project's
virtual environment (.venv) needs kittenml.

Usage:
    python kitten_bridge.py voices
    python kitten_bridge.py say   --text "..." --out out.wav [--voice Bruno]
    python kitten_bridge.py clone --text "..." --out out.wav --reference ref.wav
                                  [--reference-text "what ref.wav says"]
    python kitten_bridge.py transcribe --audio a.wav [b.wav ...] [--language ro]
    common options: --seed N (reproducible), --no-normalize (skip the English
                    text normaliser, e.g. for Romanian)

Every command prints exactly one JSON line on stdout, which MATLAB parses
with jsondecode. Progress and warnings go to stderr.
"""

import argparse
import json
import os
import subprocess
import sys
import time

# On Windows, Python opens text files in the ANSI code page (cp1252) unless
# told otherwise, and a file read inside the kittenml stack is UTF-8: loading
# the model failed with "UnicodeDecodeError: 'charmap' codec can't decode
# byte 0x9d". UTF-8 mode fixes every such open() at once. It must be set at
# interpreter start, so the script relaunches itself with -X utf8 if needed.
if not sys.flags.utf8_mode:
    sys.exit(subprocess.call([sys.executable, "-X", "utf8", *sys.argv]))

MODEL_ID = "KittenML/kitten-tts-2"


def emit(**kw):
    print(json.dumps(kw), flush=True)


def load_model():
    from kittenml import KittenTTS  # imported late: slow, and only needed here
    t0 = time.time()
    m = KittenTTS(MODEL_ID)
    print(f"[bridge] model loaded in {time.time() - t0:.1f}s", file=sys.stderr)
    return m


def list_voices(m):
    v = m.available_voices
    v = v() if callable(v) else v
    return sorted(v.keys()) if isinstance(v, dict) else sorted(list(v))


def transcribe(paths, language):
    """Whisper large-v3 (the model kittenml itself uses) on any language.

    kittenml's own transcriber hard-codes language="en", so it would force a
    Romanian clip into English words. Here the language is a parameter.
    Several files share one model load, which takes longer than transcribing.
    """
    import librosa
    import torch
    from transformers import pipeline
    cuda = torch.cuda.is_available()
    asr = pipeline("automatic-speech-recognition", model="openai/whisper-large-v3",
                   chunk_length_s=30, device=0 if cuda else -1,
                   dtype=torch.float16 if cuda else torch.float32)
    kw = {"language": language} if language else {}
    texts = []
    for path in paths:
        wav, _ = librosa.load(path, sr=16000, mono=True)
        texts.append(asr(wav, generate_kwargs=kw)["text"].strip())
    return texts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["voices", "say", "clone", "transcribe"])
    ap.add_argument("--audio", nargs="+", help="transcribe: the WAV file(s) to transcribe")
    ap.add_argument("--language", default=None,
                    help='transcribe: e.g. "en", "ro"; omitted = auto-detect')
    ap.add_argument("--text")
    ap.add_argument("--out")
    ap.add_argument("--voice", default=None)
    ap.add_argument("--reference", default=None)
    ap.add_argument("--reference-text", default=None,
                    help="transcript of the reference; Whisper transcribes it if omitted")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--no-normalize", action="store_true")
    a = ap.parse_args()

    try:
        if a.command == "transcribe":
            if not a.audio:
                raise ValueError("transcribe needs --audio <wav>")
            texts = transcribe(a.audio, a.language)
            emit(ok=True, text=texts[0], texts=texts, language=a.language)
            return
        m = load_model()
        if a.command == "voices":
            emit(ok=True, voices=list_voices(m))
            return

        if not a.text or not a.out:
            raise ValueError("--text and --out are required")

        kw = {}
        if a.command == "clone":
            if not a.reference:
                raise ValueError("clone needs --reference <wav>")
            kw["reference"] = a.reference
            if a.reference_text:
                kw["reference_text"] = a.reference_text
        elif a.voice:
            kw["voice"] = a.voice
        if a.no_normalize:
            kw["normalize"] = False
        if a.seed is not None:
            kw["advanced"] = {"seed": a.seed}

        import numpy as np
        import soundfile as sf

        t0 = time.time()
        audio = m.generate(a.text, **kw)
        secs = time.time() - t0
        if hasattr(audio, "detach"):          # torch tensor -> numpy
            audio = audio.detach().cpu().numpy()
        audio = np.asarray(audio, dtype=np.float32).squeeze()
        sf.write(a.out, audio, m.sample_rate)
        emit(ok=True, out=a.out, fs=int(m.sample_rate),
             durationSec=round(len(audio) / m.sample_rate, 3),
             synthSec=round(secs, 2), args=kw)
    except Exception as e:  # MATLAB shows this message instead of a traceback
        # A GPU can run out of memory although it reports free memory: on
        # Windows the driver (WDDM) limits each process's share, and another
        # program using the GPU (MATLAB's own figures) lowers it. The same
        # call then still works on the CPU, only slower - so retry there once
        # instead of failing. "-1" hides every GPU; an EMPTY value would not
        # work, because Windows deletes environment variables set to "".
        if type(e).__name__ == "OutOfMemoryError" and os.environ.get("CUDA_VISIBLE_DEVICES") != "-1":
            print("[bridge] CUDA out of memory - retrying on the CPU (slower)", file=sys.stderr)
            env = dict(os.environ, CUDA_VISIBLE_DEVICES="-1")
            sys.exit(subprocess.call([sys.executable, "-X", "utf8", *sys.argv], env=env))
        emit(ok=False, error=f"{type(e).__name__}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
