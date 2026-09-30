# Downloads the offline STT/MT model assets iTantra needs at runtime.
# Not committed to git (see .gitignore) because of their size (~300MB total).
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$ModelsDir = "assets/models"
New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null

function Get-Model($Url, $Dest) {
    if (Test-Path $Dest) {
        Write-Host "skip (exists): $Dest"
        return
    }
    Write-Host "downloading: $Dest"
    Invoke-WebRequest -Uri $Url -OutFile "$Dest.part"
    Move-Item "$Dest.part" $Dest -Force
}

# --- Vosk STT models (kept as zip; vosk_flutter's ModelLoader unzips them) ---
# English uses the mid-tier "lgraph" model (~125MB) for meaningfully better
# accuracy than the small tier; Hindi has no such middle ground (it's
# small-42MB or full-1.5GB), so it stays on small.
Get-Model "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip" "$ModelsDir/vosk-model-en-us-0.22-lgraph.zip"
Get-Model "https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip" "$ModelsDir/vosk-model-small-hi-0.22.zip"

# --- Marian/OPUS-MT translation models (quantized ONNX), en<->hi ---
foreach ($dir in @("en-hi", "hi-en")) {
    $out = "$ModelsDir/mt-$dir"
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    $base = "https://huggingface.co/Xenova/opus-mt-$dir/resolve/main"
    Get-Model "$base/onnx/encoder_model_quantized.onnx" "$out/encoder_model_quantized.onnx"
    Get-Model "$base/onnx/decoder_model_quantized.onnx" "$out/decoder_model_quantized.onnx"
    Get-Model "$base/source.spm" "$out/source.spm"
    Get-Model "$base/target.spm" "$out/target.spm"
    Get-Model "$base/vocab.json" "$out/vocab.json"
    Get-Model "$base/generation_config.json" "$out/generation_config.json"
}

Write-Host "All model assets downloaded into $ModelsDir"
