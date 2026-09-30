#!/usr/bin/env bash
# Downloads the offline STT/MT model assets iTantra needs at runtime.
# Not committed to git (see .gitignore) because of their size (~300MB total).
set -euo pipefail
cd "$(dirname "$0")/.."

MODELS_DIR="assets/models"
mkdir -p "$MODELS_DIR"

download() {
  local url="$1" dest="$2"
  if [ -f "$dest" ]; then
    echo "skip (exists): $dest"
    return
  fi
  echo "downloading: $dest"
  curl -L --fail --retry 3 -o "$dest.part" "$url"
  mv "$dest.part" "$dest"
}

# --- Vosk STT models (kept as zip; vosk_flutter's ModelLoader unzips them) ---
# English uses the mid-tier "lgraph" model (~125MB) for meaningfully better
# accuracy than the small tier; Hindi has no such middle ground (it's
# small-42MB or full-1.5GB), so it stays on small.
download "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip" "$MODELS_DIR/vosk-model-en-us-0.22-lgraph.zip"
download "https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip" "$MODELS_DIR/vosk-model-small-hi-0.22.zip"

# --- Marian/OPUS-MT translation models (quantized ONNX), en<->hi ---
for dir in en-hi hi-en; do
  out="$MODELS_DIR/mt-$dir"
  mkdir -p "$out"
  base="https://huggingface.co/Xenova/opus-mt-$dir/resolve/main"
  download "$base/onnx/encoder_model_quantized.onnx" "$out/encoder_model_quantized.onnx"
  download "$base/onnx/decoder_model_quantized.onnx" "$out/decoder_model_quantized.onnx"
  download "$base/source.spm" "$out/source.spm"
  download "$base/target.spm" "$out/target.spm"
  download "$base/vocab.json" "$out/vocab.json"
  download "$base/generation_config.json" "$out/generation_config.json"
done

echo "All model assets downloaded into $MODELS_DIR"
