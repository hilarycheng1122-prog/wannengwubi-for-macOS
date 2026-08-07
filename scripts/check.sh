#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"

while IFS= read -r yaml_file; do
  ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "$yaml_file"
done < <(find "$PROJECT_ROOT/config" "$PROJECT_ROOT/features" -type f -name '*.yaml' -print)

plutil -lint "$PROJECT_ROOT/packaging/macos/Info.single-mode.experimental.plist" >/dev/null

rg -q 'schema_id: wubi_pinyin_local' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q '万能五笔' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'initial_quality: 100' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'name: zh_trad' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -Uq 'name: zh_trad\n    reset: 0' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'states: \[ 简体, 繁體 \]' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'opencc_config: s2t.json' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -Fq 'accept: "Control+Shift+T", toggle: zh_trad' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'style/candidate_list_layout: linear' "$PROJECT_ROOT/config/rime/squirrel.custom.yaml"
rg -q 'style/text_orientation: horizontal' "$PROJECT_ROOT/config/rime/squirrel.custom.yaml"

if find "$PROJECT_ROOT" -path "$PROJECT_ROOT/.git" -prune -o \( -name '*.userdb' -o -name '*.bin' -o -name 'installation.yaml' \) -print | grep -q .; then
  echo '发现不应提交的个人数据或编译产物。' >&2
  exit 1
fi

echo '配置、品牌清单和仓库卫生检查通过。'
