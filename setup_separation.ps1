# One-time setup for the separation models (Weeks 5-7).
# Run after setup_tts.ps1, from PowerShell inside the project folder:
#     powershell -ExecutionPolicy Bypass -File .\setup_separation.ps1
#
# 1. MATLAB separateSpeakers models (Conv-TasNet, SepFormer 2/3), ~200 MB,
#    from MathWorks, unpacked into models\separateSpeakers.
# 2. MossFormer2 (ClearerVoice-Studio) and TIGER into the project's .venv.
#
# The pip packages are installed WITHOUT their pinned dependencies on
# purpose: clearvoice pins numpy<2 and pulls a CPU-only torch, which would
# break KittenTTS and the CUDA build of PyTorch. The few modules the
# separation code really imports are listed below. TIGER is not installed at
# all: separate_bridge.py loads its network straight from the cloned repo.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
# Native commands (py, pip, git) do not stop the script on failure in
# Windows PowerShell 5.1, even with 'Stop': check every exit code.
function Invoke-Checked([scriptblock]$cmd) {
    & $cmd
    if ($LASTEXITCODE -ne 0) { throw "Failed (exit $LASTEXITCODE): $cmd" }
}

$py = '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Run setup_tts.ps1 first.' }

if (-not (Test-Path models\separateSpeakers\separateSpeakers\sepformer-libri2mix-upit.mat)) {
    New-Item -ItemType Directory -Force models | Out-Null
    $zip = 'models\separateSpeakers.zip'
    Invoke-WebRequest https://ssd.mathworks.com/supportfiles/audio/separateSpeakers.zip -OutFile $zip
    Expand-Archive $zip -DestinationPath models\separateSpeakers -Force
    Remove-Item $zip
}

Invoke-Checked { & $py -m pip install --no-deps clearvoice==0.1.2 yamlargparse torchinfo pydub `
    rotary-embedding-torch==0.8.3 python_speech_features==0.6 }

if (-not (Test-Path models\TIGER)) {
    Invoke-Checked { git clone --depth 1 https://github.com/JusperLee/TIGER.git models\TIGER }
}

# First use downloads the weights: MossFormer2 into models\clearvoice,
# TIGER into models\TIGER_cache.
