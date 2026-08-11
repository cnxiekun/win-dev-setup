#!/usr/bin/env bash
# apply-env.sh — 应用 .env 到 config/ 下所有占位符
# 用法: bash scripts/apply-env.sh [.env路径]
# 说明: 把 config/ 里的 ${KEY} 占位符替换为 .env 中的真实值
#       默认在仓库根目录生成一份"已填充"副本到 .build/，不污染 config/

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$REPO_ROOT/.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "✗ 未找到 $ENV_FILE，请先复制 .env.example 为 .env"
  exit 1
fi

echo "=== 读取 .env 变量 ==="
declare -A VARS
while IFS='=' read -r key val; do
  case "$key" in ''|\#*) continue ;; esac
  VARS["$key"]="$val"
  echo "  $key = ***"
done < "$ENV_FILE"

echo ""
echo "=== 替换占位符 → .build/ ==="
BUILD_DIR="$REPO_ROOT/.build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

find "$REPO_ROOT/config" -type f ! -name '*.pyc' | while read -r f; do
  rel="${f#$REPO_ROOT/config/}"
  out="$BUILD_DIR/$rel"
  mkdir -p "$(dirname "$out")"
  sed_cmds=()
  for k in "${!VARS[@]}"; do
    # 转义特殊字符避免 sed 出错
    esc_v=$(printf '%s' "${VARS[$k]}" | sed 's/[&/\]/\\&/g')
    sed_cmds+=("-e" "s/\\\${$k}/$esc_v/g")
  done
  sed "${sed_cmds[@]}" "$f" > "$out"
done
echo "✓ 已生成 .build/ 目录，包含填充后的配置"

echo ""
echo "=== 提示 ==="
echo "  .build/ 下的文件是填充后的配置，可直接拷贝到 ~/.claude 等位置"
echo "  config/ 保持占位符状态，安全可提交到 git"
