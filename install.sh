#!/usr/bin/env bash
# ============================================================
# win-dev-setup 一键安装（bash 版）
# 用法: curl -fsSL https://raw.githubusercontent.com/cnxiekun/win-dev-setup/master/install.sh | bash
# 作用: 在当前目录 clone 仓库 → 交互填写 API key → 调 setup.sh 完成配置
# 说明: 需要已有 Git Bash；若只有 PowerShell 请用 install.ps1
# ============================================================
set -euo pipefail

REPO_URL="https://github.com/cnxiekun/win-dev-setup.git"
REPO_DIR="win-dev-setup"

echo "== win-dev-setup 一键安装 =="

# ---------- 1. 准备仓库（clone 或更新）----------
if [ -d "$REPO_DIR/.git" ]; then
  echo "> 检测到已有 $REPO_DIR，git pull 更新..."
  git -C "$REPO_DIR" pull --ff-only || echo "  ⚠ pull 失败（网络？），继续用现有代码"
elif [ -d "$REPO_DIR" ]; then
  echo "✗ $REPO_DIR 已存在但非 git 仓库，请手动处理后重试。" >&2
  exit 1
else
  echo "> 正在 clone 仓库到 $REPO_DIR/ ..."
  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    echo "✗ clone 失败（网络问题？）。可重试，或改用分步安装（git clone 后本地跑 setup.sh）。" >&2
    exit 1
  fi
fi
cd "$REPO_DIR"

# ---------- 2. 生成 .env（交互填 key）----------
if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "> 请填写以下 API key（直接回车跳过，可稍后在 .env 补填后重跑 setup.sh）："
  for key in DEEPSEEK_API_KEY AGNES_API_KEY KIMI_API_KEY TUSHARE_TOKEN TAVILY_API_KEY; do
    read -rp "  $key: " val
    if [ -n "$val" ]; then
      # 替换 .env 里对应行（key 值一般不含 | & / 等 sed 特殊字符）
      sed -i "s|^$key=.*|$key=$val|" .env
      echo "    ✓ 已填写"
    fi
  done
  echo ""
else
  echo "> 已存在 .env，跳过填写（可直接修改 .env）"
fi

# ---------- 3. 配置 ----------
echo "> 开始配置..."
bash scripts/setup.sh
