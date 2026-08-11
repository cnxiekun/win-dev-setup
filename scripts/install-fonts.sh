#!/usr/bin/env bash
# install-fonts.sh — 安装 Maple Mono NF CN 字体（开源，从 GitHub Releases 下载）
# 用法: bash scripts/install-fonts.sh [版本]
# 默认版本: v7.9（可按需指定其他 tag）
set -euo pipefail

VERSION="${1:-v7.9}"
FONT_ZIP="MapleMono-NF-CN.zip"
DOWNLOAD_URL="https://github.com/subframe7536/maple-font/releases/download/${VERSION}/${FONT_ZIP}"
WORK_DIR="$(mktemp -d)"
FONT_DEST="${LOCALAPPDATA:-$HOME/AppData/Local}/Microsoft/Windows/Fonts"

echo "=== 下载 Maple Mono NF CN ${VERSION} ==="
echo "  来源: $DOWNLOAD_URL"
curl -L -o "$WORK_DIR/$FONT_ZIP" "$DOWNLOAD_URL" --fail --progress-bar
echo "  下载完成: $(du -h "$WORK_DIR/$FONT_ZIP" | cut -f1)"

echo ""
echo "=== 解压 ==="
cd "$WORK_DIR"
if command -v unzip >/dev/null 2>&1; then
  unzip -q "$FONT_ZIP"
else
  # Git Bash 自带 unzip 通常不可用，用 python
  python -c "import zipfile; zipfile.ZipFile(r'$WORK_DIR/$FONT_ZIP').extractall(r'$WORK_DIR')"
fi
echo "  解压完成"

echo ""
echo "=== 安装到 Windows 字体目录 ==="
mkdir -p "$FONT_DEST"
COUNT=0
for f in "$WORK_DIR"/*.ttf "$WORK_DIR"/MapleMono*/fonts/*.ttf; do
  if [ -f "$f" ]; then
    cp "$f" "$FONT_DEST/"
    COUNT=$((COUNT+1))
  fi
done
echo "  已安装 $COUNT 个字体文件 → $FONT_DEST"

echo ""
echo "=== 注册到 Windows（可选，让应用识别）==="
# 通过注册表注册字体（需要管理员；普通复制也能被大多数应用识别）
if [ "$(id -u)" = "0" ] 2>/dev/null; then
  echo "  （root 环境，跳过注册表注册）"
fi

echo ""
echo "✓ Maple Mono NF CN 安装完成"
echo "  字体文件: $FONT_DEST/MapleMono-NF-CN-*.ttf"
echo "  提示: 重启终端/编辑器后，在设置中选择 'Maple Mono NF CN' 字体"

rm -rf "$WORK_DIR"
