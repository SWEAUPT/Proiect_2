# One-time setup for KittenTTS 2 and Whisper (Weeks 3-7).
#
# Creates .venv (Python 3.12) with PyTorch and kittenml.
# Run from PowerShell inside the project folder:
#     powershell -ExecutionPolicy Bypass -File .\setup_tts.ps1
#
# GPU: an NVIDIA card makes synthesis several times faster. The script
# installs the CUDA 12.8 build of PyTorch, which also runs (slowly) on CPU.
# Pass -Cpu to install the much smaller CPU-only build instead.
param([switch]$Cpu)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
# Native commands (py, pip, git) do not stop the script on failure in
# Windows PowerShell 5.1, even with 'Stop': check every exit code.
function Invoke-Checked([scriptblock]$cmd) {
    & $cmd
    if ($LASTEXITCODE -ne 0) { throw "Failed (exit $LASTEXITCODE): $cmd" }
}

if (-not (Test-Path .venv\Scripts\python.exe)) {
    Invoke-Checked { py -3.12 -m venv .venv }
}
$py = '.venv\Scripts\python.exe'
Invoke-Checked { & $py -m pip install --upgrade pip }
$index = if ($Cpu) { 'https://download.pytorch.org/whl/cpu' } else { 'https://download.pytorch.org/whl/cu128' }
Invoke-Checked { & $py -m pip install torch torchaudio --index-url $index }
Invoke-Checked { & $py -m pip install kittenml }

# First call downloads the model (~1 GB) into the Hugging Face cache.
Invoke-Checked { & $py kitten_bridge.py voices }
