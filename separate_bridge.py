"""Bridge between MATLAB and two Python speech separators.

    mossformer2  MossFormer2_SS_16K from ClearerVoice-Studio (alibabasglab),
                 trained on WSJ0-2mix at 16 kHz. Two speakers.
    tiger        TIGER (JusperLee/TIGER-speech, ICLR 2025), trained on EchoSet
                 (reverberant, noisy) at 16 kHz. Two speakers.

Usage:
    python separate_bridge.py --model tiger --mix a.wav [b.wav ...] --outdir out/

For every mixture <name>.wav it writes <outdir>/<name>_<model>_y1.wav, _y2.wav
(16 kHz, float32, raw network scale - MATLAB applies the gains). Several
mixtures share one model load. Prints exactly one JSON line on stdout, like
kitten_bridge.py; progress and warnings go to stderr.

Runs on the GPU when CUDA is available, otherwise on the CPU.
"""

import argparse
import contextlib
import json
import os
import subprocess
import sys
import time

# Same reason as in kitten_bridge.py: UTF-8 mode must be set at start-up.
if not sys.flags.utf8_mode:
    sys.exit(subprocess.call([sys.executable, "-X", "utf8", *sys.argv]))

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = os.path.join(HERE, "models")
FS = 16000


def emit(**kw):
    print(json.dumps(kw), flush=True)


def load_mossformer2():
    from clearvoice import ClearVoice
    # ClearVoice keeps its checkpoints under ./checkpoints of the CURRENT
    # folder, and downloads them there on first use (~ 230 MB).
    os.makedirs(os.path.join(MODELS, "clearvoice"), exist_ok=True)
    os.chdir(os.path.join(MODELS, "clearvoice"))
    import torch
    m = ClearVoice(task="speech_separation", model_names=["MossFormer2_SS_16K"]).models[0]

    # The network is called directly, once on the whole signal. ClearVoice's
    # own decoder cuts anything longer than 2 s into 2 s windows and separates
    # each one independently - and a separator's output ORDER is arbitrary in
    # every window, so the speakers can swap places from one window to the
    # next. It also runs without no_grad, which is slow.
    def run(x):
        with torch.no_grad():
            out = m.model(torch.from_numpy(x).float().to(m.device)[None, :])  # list of [1, T]
        return [o[0].cpu().numpy() for o in out]
    return run


def load_tiger():
    import importlib
    import types
    import torch
    root = os.path.join(MODELS, "TIGER", "look2hear")
    # The package __init__ files of the TIGER repo import its whole training
    # stack (PyTorch Lightning, torch_complex, ...). The network itself needs
    # only tiger.py, base_model.py and two layer files, so the packages are
    # registered empty and only those modules are loaded.
    for name, sub in [("look2hear", ""), ("look2hear.layers", "layers"),
                      ("look2hear.models", "models")]:
        pkg = types.ModuleType(name)
        pkg.__path__ = [os.path.join(root, sub) if sub else root]
        sys.modules[name] = pkg
    TIGER = importlib.import_module("look2hear.models.tiger").TIGER
    dev = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    net = TIGER.from_pretrained("JusperLee/TIGER-speech",
                                cache_dir=os.path.join(MODELS, "TIGER_cache"))
    net.to(dev).eval()

    def run(x):
        with torch.no_grad():
            y = net(torch.from_numpy(x).float().to(dev)[None, None, :])  # [1, spk, T]
        return list(y.squeeze(0).cpu().numpy())
    return run


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, choices=["mossformer2", "tiger"])
    ap.add_argument("--mix", nargs="+", required=True)
    ap.add_argument("--outdir", required=True)
    a = ap.parse_args()
    try:
        import numpy as np
        import soundfile as sf
        import librosa
        import torch
        mixes = [os.path.abspath(m) for m in a.mix]
        outdir = os.path.abspath(a.outdir)
        os.makedirs(outdir, exist_ok=True)

        t0 = time.time()
        with contextlib.redirect_stdout(sys.stderr):   # keep stdout for the JSON line
            run = load_mossformer2() if a.model == "mossformer2" else load_tiger()
            # Warm-up: the first call on a GPU also builds its kernels, which
            # would be counted as the first mixture's separation time.
            run(np.zeros(FS, dtype=np.float32) + 1e-4)
        loadSec = time.time() - t0

        files, secs = [], []
        for m in mixes:
            x, _ = librosa.load(m, sr=FS, mono=True)
            t1 = time.time()
            with contextlib.redirect_stdout(sys.stderr):
                ys = run(x.astype(np.float32))
            if torch.cuda.is_available():
                torch.cuda.synchronize()
            secs.append(round(time.time() - t1, 3))
            stem = os.path.splitext(os.path.basename(m))[0]
            outs = []
            for k, y in enumerate(ys, 1):
                y = np.asarray(y, dtype=np.float32)[:len(x)]
                f = os.path.join(outdir, f"{stem}_{a.model}_y{k}.wav")
                sf.write(f, y, FS, subtype="FLOAT")
                outs.append(f)
            files.append(outs)
        emit(ok=True, model=a.model, fs=FS, files=files, separateSec=secs,
             loadSec=round(loadSec, 1),
             device="cuda" if torch.cuda.is_available() else "cpu")
    except Exception as e:
        emit(ok=False, error=f"{type(e).__name__}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
