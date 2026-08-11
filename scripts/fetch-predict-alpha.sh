#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
source "$PROJECT_ROOT/upstream/versions.lock"

output="$PROJECT_ROOT/features/prediction/models/predict.db"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/wanneng-wubi-predict-alpha.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

curl --fail --location --silent --show-error \
  --output "$temp_dir/predict.db" \
  "$LIBRIME_PREDICT_ALPHA_URL"

actual_sha="$(shasum -a 256 "$temp_dir/predict.db" | awk '{print $1}')"
[[ "$actual_sha" == "$LIBRIME_PREDICT_ALPHA_SHA256" ]] || {
  echo '官方 Alpha 预测数据库校验失败。' >&2
  exit 2
}

mkdir -p "${output:h}"
mv "$temp_dir/predict.db" "$output"
echo "已下载并校验：$output"
