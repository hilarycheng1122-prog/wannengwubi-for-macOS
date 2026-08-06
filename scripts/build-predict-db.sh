#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
MAKE_PREDICT_DATA_BIN="${MAKE_PREDICT_DATA_BIN:-make_predict_data}"
BUILD_PREDICT_BIN="${BUILD_PREDICT_BIN:-build_predict}"
OUTPUT="$PROJECT_ROOT/features/prediction/models/predict.db"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wanneng-wubi-predict.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

command -v "$MAKE_PREDICT_DATA_BIN" >/dev/null || {
  echo '缺少 make_predict_data；请从 rime/librime-predict 构建该工具。' >&2
  exit 2
}
command -v "$BUILD_PREDICT_BIN" >/dev/null || {
  echo '缺少 build_predict；请从 rime/librime-predict 构建该工具。' >&2
  exit 3
}

inputs=("$PROJECT_ROOT"/features/prediction/corpus/public/*.tsv(N))
inputs+=("$PROJECT_ROOT"/features/prediction/corpus/private/*.tsv(N))
(( ${#inputs[@]} > 0 )) || { echo '没有可用的预测语料。' >&2; exit 4; }

"$MAKE_PREDICT_DATA_BIN" --max-candidates 20 "${inputs[@]}" > "$TEMP_DIR/predict-data.tsv"
mkdir -p "${OUTPUT:h}"
"$BUILD_PREDICT_BIN" "$OUTPUT" < "$TEMP_DIR/predict-data.tsv"
echo "已生成：$OUTPUT"

