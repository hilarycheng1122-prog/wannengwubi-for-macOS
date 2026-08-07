#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
RIME_DIR="${RIME_USER_DIR:-$HOME/Library/Rime}"
ENABLE_PREDICTION=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --prediction) ENABLE_PREDICTION=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "未知参数：$arg" >&2; exit 2 ;;
  esac
done

files=(
  default.custom.yaml
  squirrel.custom.yaml
  wubi86.schema.yaml
  wubi_pinyin_local.schema.yaml
)

if $DRY_RUN; then
  echo "将安装到：$RIME_DIR"
  printf '  %s\n' "${files[@]}" wubi86.dict.yaml
  $ENABLE_PREDICTION && printf '  %s\n' wubi_pinyin_local.custom.yaml predict.db
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$RIME_DIR/backups/wanneng-wubi-$timestamp"
mkdir -p "$RIME_DIR" "$backup_dir"

for name in "${files[@]}" wubi86.dict.yaml wubi_pinyin_local.custom.yaml predict.db; do
  if [[ -e "$RIME_DIR/$name" ]]; then
    cp -p "$RIME_DIR/$name" "$backup_dir/$name"
  fi
done

for name in "${files[@]}"; do
  cp "$PROJECT_ROOT/config/rime/$name" "$RIME_DIR/$name"
done
cp "$PROJECT_ROOT/dictionaries/wubi86.dict.yaml" "$RIME_DIR/wubi86.dict.yaml"

if $ENABLE_PREDICTION; then
  plugin='/Library/Input Methods/Squirrel.app/Contents/Frameworks/rime-plugins/librime-predict.dylib'
  model="$PROJECT_ROOT/features/prediction/models/predict.db"
  [[ -f "$plugin" ]] || { echo '当前鼠须管不含 librime-predict。' >&2; exit 3; }
  [[ -f "$model" ]] || { echo '请先执行 make prediction 生成 predict.db。' >&2; exit 4; }
  cp "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml" "$RIME_DIR/"
  cp "$model" "$RIME_DIR/predict.db"
fi

deployer='/Library/Input Methods/Squirrel.app/Contents/MacOS/rime_deployer'
if [[ -x "$deployer" ]]; then
  shared_dir='/Library/Input Methods/Squirrel.app/Contents/SharedSupport'
  "$deployer" --build "$RIME_DIR" "$shared_dir" "$RIME_DIR/build" || \
    echo '自动部署未完成，请从输入法菜单选择“重新部署”。'
fi

echo "配置已安装；原文件备份在：$backup_dir"
