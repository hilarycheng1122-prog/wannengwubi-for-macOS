#!/bin/zsh
set -euo pipefail

RIME_DIR="${RIME_USER_DIR:-$HOME/Library/Rime}"
DATABASE="$RIME_DIR/personal_predict.userdb"

if [[ ! -d "$DATABASE" ]]; then
  echo '尚未产生个人学习数据。'
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$RIME_DIR/backups/personal-learning-$timestamp"
mkdir -p "$backup_dir"

killall Squirrel 2>/dev/null || true
mv "$DATABASE" "$backup_dir/"

echo "个人学习记录已清空；可恢复备份在：$backup_dir/personal_predict.userdb"
