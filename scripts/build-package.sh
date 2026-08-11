#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
source "$PROJECT_ROOT/upstream/versions.lock"

PRODUCT_VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
BASE_PKG="${BASE_PKG:-$PROJECT_ROOT/vendor/cache/Squirrel-$SQUIRREL_VERSION.pkg}"
MODEL="$PROJECT_ROOT/features/prediction/models/predict.db"
OUTPUT="${OUTPUT:-$PROJECT_ROOT/dist/WanNengWubi-v$PRODUCT_VERSION.pkg}"
SQUIRREL_URL="https://github.com/rime/squirrel/releases/download/$SQUIRREL_VERSION/Squirrel-$SQUIRREL_VERSION.pkg"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wanneng-wubi-package.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

if [[ ! -f "$BASE_PKG" ]]; then
  mkdir -p "${BASE_PKG:h}"
  echo "正在下载官方鼠须管 $SQUIRREL_VERSION…"
  curl --fail --location --progress-bar "$SQUIRREL_URL" --output "$BASE_PKG"
fi

actual_sha="$(shasum -a 256 "$BASE_PKG" | awk '{print $1}')"
[[ "$actual_sha" == "$SQUIRREL_PKG_SHA256" ]] || {
  echo '上游鼠须管安装包校验失败，停止构建。' >&2
  exit 2
}

[[ -f "$MODEL" ]] || {
  echo '缺少通用联想数据库，请先执行 make prediction-alpha。' >&2
  exit 3
}

model_sha="$(shasum -a 256 "$MODEL" | awk '{print $1}')"
[[ "$model_sha" == "$LIBRIME_PREDICT_ALPHA_SHA256" ]] || {
  echo '通用联想数据库校验失败，停止构建。' >&2
  exit 4
}

pkgutil --expand-full "$BASE_PKG" "$TEMP_DIR/squirrel-expanded"
source_app="$(find "$TEMP_DIR/squirrel-expanded" -type d -name 'Squirrel.app' -print -quit)"
[[ -n "$source_app" ]] || {
  echo '官方安装包中没有找到 Squirrel.app。' >&2
  exit 5
}

payload="$TEMP_DIR/payload"
payload_app="$payload/Library/Input Methods/Squirrel.app"
support="$payload/Library/Application Support/WanNengWubi/rime"
mkdir -p "${payload_app:h}" "$support/lua"
ditto "$source_app" "$payload_app"

# 保留鼠须管运行能力，只把品牌和输入源名称替换为万能五笔。
cp "$PROJECT_ROOT/packaging/macos/Info.single-mode.experimental.plist" \
  "$payload_app/Contents/Info.plist"

module_cache="$TEMP_DIR/module-cache"
iconset="$TEMP_DIR/WanNengWubi.iconset"
mkdir -p "$module_cache" "$iconset"
swiftc -module-cache-path "$module_cache" \
  "$PROJECT_ROOT/tools/icons/make_iconset.swift" -o "$TEMP_DIR/make_iconset"
swiftc -module-cache-path "$module_cache" \
  "$PROJECT_ROOT/tools/icons/make_icns.swift" -o "$TEMP_DIR/make_icns"
"$TEMP_DIR/make_iconset" "$PROJECT_ROOT/assets/app-icon-source.png" "$iconset"
"$TEMP_DIR/make_icns" "$iconset" "$payload_app/Contents/Resources/Rime.icns"
cp "$PROJECT_ROOT/assets/menu-icon.pdf" \
  "$payload_app/Contents/Resources/WanNengWubiMenu-v6.pdf"
cp "$PROJECT_ROOT/assets/menu-icon.pdf" "$payload_app/Contents/Resources/rime.pdf"

for strings in "$payload_app"/Contents/Resources/{en,zh-Hans,zh-Hant}.lproj/InfoPlist.strings; do
  [[ -f "$strings" ]] || continue
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName 万能五笔' "$strings"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName 万能五笔' "$strings"
  /usr/libexec/PlistBuddy -c 'Set :im.rime.inputmethod.Squirrel 万能五笔' "$strings"
done

# 配置由安装后脚本写入当前登录用户目录，避免把其他用户的数据打进安装包。
for name in default.custom.yaml squirrel.custom.yaml wubi86.schema.yaml \
  wubi_pinyin_local.schema.yaml; do
  cp "$PROJECT_ROOT/config/rime/$name" "$support/$name"
done
cp "$PROJECT_ROOT/dictionaries/wubi86.dict.yaml" "$support/wubi86.dict.yaml"
cp "$PROJECT_ROOT/features/prediction/universal_learning.custom.yaml" \
  "$support/wubi_pinyin_local.custom.yaml"
cp "$MODEL" "$support/predict.db"
cp "$PROJECT_ROOT/features/prediction/lua/personal_predict.lua" \
  "$support/lua/personal_predict.lua"
cp "$PROJECT_ROOT/LICENSE" \
  "$payload/Library/Application Support/WanNengWubi/LICENSE.txt"
cp "$PROJECT_ROOT/licenses/THIRD_PARTY_NOTICES.md" \
  "$payload/Library/Application Support/WanNengWubi/THIRD_PARTY_NOTICES.md"

xattr -cr "$payload"
find "$payload" -name '._*' -delete
codesign --force --deep --sign - "$payload_app"
codesign --verify --deep --strict "$payload_app"

component="$TEMP_DIR/WanNengWubi-component.pkg"
pkgbuild --root "$payload" \
  --scripts "$PROJECT_ROOT/packaging/macos/scripts" \
  --identifier local.wannengwubi.installer \
  --version "$PRODUCT_VERSION" \
  --install-location / \
  --ownership recommended \
  "$component"

sed "s/@VERSION@/$PRODUCT_VERSION/g" \
  "$PROJECT_ROOT/packaging/macos/Distribution.xml" > "$TEMP_DIR/Distribution.xml"
mkdir -p "${OUTPUT:h}"
productbuild --distribution "$TEMP_DIR/Distribution.xml" \
  --resources "$PROJECT_ROOT/packaging/macos/resources" \
  --package-path "$TEMP_DIR" \
  "$OUTPUT"

pkgutil --expand-full "$OUTPUT" "$TEMP_DIR/verify"
installed_schema="$(find "$TEMP_DIR/verify" -path '*/wubi_pinyin_local.schema.yaml' -print -quit)"
installed_model="$(find "$TEMP_DIR/verify" -path '*/predict.db' -print -quit)"
installed_app="$(find "$TEMP_DIR/verify" -type d -name 'Squirrel.app' -print -quit)"
[[ -f "$installed_schema" && -f "$installed_model" && -d "$installed_app" ]] || {
  echo '安装包内容验证失败。' >&2
  exit 6
}
rg -q "version: \"$PRODUCT_VERSION\"" "$installed_schema"
[[ "$(shasum -a 256 "$installed_model" | awk '{print $1}')" == \
  "$LIBRIME_PREDICT_ALPHA_SHA256" ]]
codesign --verify --deep --strict "$installed_app"

echo "已生成：$OUTPUT"
echo "SHA-256：$(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
