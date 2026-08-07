#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
source "$PROJECT_ROOT/upstream/versions.lock"

BASE_PKG="${BASE_PKG:-$PROJECT_ROOT/vendor/cache/Squirrel-$SQUIRREL_VERSION.pkg}"
OUTPUT="$PROJECT_ROOT/dist/WanNengWubi-$PRODUCT_VERSION.pkg"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wanneng-wubi-package.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

[[ -f "$BASE_PKG" ]] || {
  echo "请把官方 Squirrel $SQUIRREL_VERSION 安装包放到：$BASE_PKG" >&2
  exit 2
}

actual_sha="$(shasum -a 256 "$BASE_PKG" | awk '{print $1}')"
[[ "$actual_sha" == "$SQUIRREL_PKG_SHA256" ]] || {
  echo '上游安装包校验失败，停止构建。' >&2
  exit 3
}

pkgutil --expand-full "$BASE_PKG" "$TEMP_DIR/expanded"
source_app="$(find "$TEMP_DIR/expanded" -type d -name 'Squirrel.app' -print -quit)"
[[ -n "$source_app" ]] || { echo '安装包中未找到 Squirrel.app。' >&2; exit 4; }

payload_app="$TEMP_DIR/payload/Library/Input Methods/Squirrel.app"
mkdir -p "${payload_app:h}"
ditto "$source_app" "$payload_app"

# 单输入源清单仍是实验项；发布前必须完成真实输入回归测试。
cp "$PROJECT_ROOT/packaging/macos/Info.single-mode.experimental.plist" "$payload_app/Contents/Info.plist"

module_cache="$TEMP_DIR/module-cache"
mkdir -p "$module_cache" "$TEMP_DIR/WanNengWubi.iconset"
swiftc -module-cache-path "$module_cache" "$PROJECT_ROOT/tools/icons/make_iconset.swift" -o "$TEMP_DIR/make_iconset"
swiftc -module-cache-path "$module_cache" "$PROJECT_ROOT/tools/icons/make_icns.swift" -o "$TEMP_DIR/make_icns"
"$TEMP_DIR/make_iconset" "$PROJECT_ROOT/assets/app-icon-source.png" "$TEMP_DIR/WanNengWubi.iconset"
"$TEMP_DIR/make_icns" "$TEMP_DIR/WanNengWubi.iconset" "$payload_app/Contents/Resources/Rime.icns"
cp "$PROJECT_ROOT/assets/menu-icon.pdf" "$payload_app/Contents/Resources/WanNengWubiMenu-v3.pdf"

for strings in "$payload_app"/Contents/Resources/{en,zh-Hans,zh-Hant}.lproj/InfoPlist.strings; do
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName 万能五笔' "$strings"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName 万能五笔' "$strings"
  /usr/libexec/PlistBuddy -c 'Set :im.rime.inputmethod.Squirrel 万能五笔' "$strings"
done

codesign --force --deep --sign - "$payload_app"
codesign --verify --deep --strict "$payload_app"
mkdir -p "${OUTPUT:h}"
pkgbuild --root "$TEMP_DIR/payload" \
  --identifier local.wannengwubi.inputmethod \
  --version "$PRODUCT_VERSION" \
  --install-location / \
  "$OUTPUT"

echo "已生成：$OUTPUT"
