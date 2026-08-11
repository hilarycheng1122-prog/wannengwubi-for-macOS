#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"

while IFS= read -r yaml_file; do
  ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "$yaml_file"
done < <(find "$PROJECT_ROOT/config" "$PROJECT_ROOT/features" -type f -name '*.yaml' -print)

plutil -lint "$PROJECT_ROOT/packaging/macos/Info.single-mode.experimental.plist" >/dev/null

rg -q 'schema_id: wubi_pinyin_local' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'version: "1.0.0"' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q '万能五笔' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'initial_quality: 100' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'name: zh_trad' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -Uq 'name: zh_simp\n    reset: 1' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'opencc_config: t2s.json' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -Uq 'name: zh_trad\n    reset: 0' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'states: \[ 简体, 繁體 \]' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'opencc_config: s2t.json' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -Fq 'accept: "Control+Shift+T", toggle: zh_trad' "$PROJECT_ROOT/config/rime/wubi_pinyin_local.schema.yaml"
rg -q 'style/candidate_list_layout: linear' "$PROJECT_ROOT/config/rime/squirrel.custom.yaml"
rg -q 'style/text_orientation: horizontal' "$PROJECT_ROOT/config/rime/squirrel.custom.yaml"
rg -q 'max_candidates: 6' "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml"
rg -q 'reset: 1' "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml"
rg -Fq 'accept: "Control+Shift+P", toggle: prediction' "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml"
rg -q 'opencc_config: t2s.json' "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml"
rg -q 'tags: \[ prediction \]' "$PROJECT_ROOT/features/prediction/wubi_pinyin_local.custom.yaml"
rg -q 'lua_processor@\*personal_predict\*processor' "$PROJECT_ROOT/features/prediction/personal_learning.custom.yaml"
rg -q 'lua_translator@\*personal_predict\*translator' "$PROJECT_ROOT/features/prediction/personal_learning.custom.yaml"
rg -q 'min_count: 2' "$PROJECT_ROOT/features/prediction/personal_learning.custom.yaml"
rg -q 'max_candidates: 7' "$PROJECT_ROOT/features/prediction/personal_learning.custom.yaml"
rg -q 'opencc_config: t2s.json' "$PROJECT_ROOT/features/prediction/personal_learning.custom.yaml"
rg -q 'input_simplification' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -q 'LevelDb' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -q 'commit_notifier' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -Fq '["Super+v"] = true' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -Fq '["Control+v"] = true' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -q 'accepted_types' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
rg -q 'engine_prediction_option' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"
if rg -q '个人 .*次' "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua"; then
  echo '个人联想候选不应显示学习次数标记。' >&2
  exit 1
fi
rg -q 'engine/processors/@before 0.*predictor' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'engine/processors/@before 1.*personal_predict' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'engine/translators/@before 0.*predict_translator' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'engine/translators/@before 1.*personal_predict' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'prediction_option: prediction_enabled' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'engine_prediction_option: prediction' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'candidate_type: prediction' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'db: predict.db' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'engine/filters/@before 0.*simplifier@input_simp' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'option_name: input_simplification' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
rg -q 'opencc_config: t2s.json' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"
if rg -q 'tags:.*prediction' "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml"; then
  echo '简体规范过滤必须覆盖普通候选和联想候选。' >&2
  exit 1
fi
zsh -n "$PROJECT_ROOT/scripts/install-config.sh"
RIME_USER_DIR=/tmp/wanneng-wubi-check "$PROJECT_ROOT/scripts/install-config.sh" \
  --universal-learning --dry-run | rg -q 'predict.db'

if find "$PROJECT_ROOT" -path "$PROJECT_ROOT/.git" -prune -o \( -name '*.userdb' -o -name '*.bin' -o -name 'installation.yaml' \) -print | grep -q .; then
  echo '发现不应提交的个人数据或编译产物。' >&2
  exit 1
fi

echo '配置、品牌清单和仓库卫生检查通过。'
