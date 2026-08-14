#!/usr/bin/env bash
# setup.sh — win-dev-setup 配置主脚本（bash）
# 由 setup.ps1 装完软件后自动调用；也可在已装好 Git 的机器上直接运行：bash scripts/setup.sh
# 职责：拷配置 → 镜像源 → 应用 .env → 装 marketplaces/plugins/skills/fonts → CC Switch → 验证
# 容错：单个步骤失败不中断整体（不用 set -e），末尾汇总"未完成项 + 重试命令"
set -uo pipefail

# 本脚本在 scripts/ 下，仓库根是它的父目录
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_HOME="${HOME:-$USERPROFILE}"

pending=()  # "说明|重试命令"

step() { echo -e "\n=== $1 ==="; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

# ---------- 1. 拷 Git 配置 ----------
step "1/7 配置 Git"
if [ -f "$REPO_ROOT/config/git/.gitconfig" ]; then
  cp "$REPO_ROOT/config/git/.gitconfig" "$DEST_HOME/.gitconfig" && ok "已复制 .gitconfig → ~/.gitconfig" || warn "复制 .gitconfig 失败"
else
  warn "缺少 config/git/.gitconfig"
fi
# git-prompt.sh（终端提示符）→ ~/.config/git/
if [ -f "$REPO_ROOT/config/git/git-prompt.sh" ]; then
  mkdir -p "$DEST_HOME/.config/git"
  cp "$REPO_ROOT/config/git/git-prompt.sh" "$DEST_HOME/.config/git/git-prompt.sh" && ok "已复制 git-prompt.sh → ~/.config/git/"
fi

# ---------- 2. 拷 Bash 配置 ----------
step "2/7 配置 Bash（Git Bash 环境）"
for f in .bashrc .bash_profile .minttyrc; do
  if [ -f "$REPO_ROOT/config/bash/$f" ]; then
    cp "$REPO_ROOT/config/bash/$f" "$DEST_HOME/$f" && ok "已复制 $f → ~/$f" || warn "复制 $f 失败"
  fi
done
# .vimrc（vim 编辑器配置）→ ~/.vimrc
if [ -f "$REPO_ROOT/config/vim/.vimrc" ]; then
  cp "$REPO_ROOT/config/vim/.vimrc" "$DEST_HOME/.vimrc" && ok "已复制 .vimrc → ~/.vimrc"
fi

# ---------- 3. 拷 Claude 配置 ----------
step "3/7 配置 Claude Code"
mkdir -p "$DEST_HOME/.claude/skills"
if [ -f "$REPO_ROOT/config/claude/CLAUDE.md" ]; then
  cp "$REPO_ROOT/config/claude/CLAUDE.md" "$DEST_HOME/.claude/CLAUDE.md" && ok "已复制全局 CLAUDE.md → ~/.claude/"
fi
if [ -d "$REPO_ROOT/config/claude/skills" ]; then
  cp -r "$REPO_ROOT/config/claude/skills/". "$DEST_HOME/.claude/skills/" 2>/dev/null && ok "已复制 skills/ → ~/.claude/skills/"
fi

# ---------- 4. 镜像源 ----------
step "4/7 配置国内镜像源（pip / npm）"
if [ -f "$REPO_ROOT/config/python/pip.conf" ]; then
  mkdir -p "$DEST_HOME/.pip"
  cp "$REPO_ROOT/config/python/pip.conf" "$DEST_HOME/.pip/pip.conf" && ok "已配置 pip 清华源 → ~/.pip/pip.conf"
fi
if [ -f "$REPO_ROOT/config/node/.npmrc" ]; then
  cp "$REPO_ROOT/config/node/.npmrc" "$DEST_HOME/.npmrc" && ok "已配置 npm npmmirror 源 → ~/.npmrc"
fi

# ---------- 5. 应用 .env ----------
step "5/7 应用 .env（API keys）"
if [ -f "$REPO_ROOT/.env" ]; then
  if bash "$REPO_ROOT/scripts/apply-env.sh"; then
    ok "已生成 .build/ 目录（含真实 key，勿 commit）"
  else
    warn "apply-env.sh 应用失败"
    pending+=("应用 .env|bash scripts/apply-env.sh")
  fi
else
  warn "未找到 .env。请先: cp .env.example .env && notepad .env"
  pending+=("填写 .env|cp .env.example .env && notepad .env")
fi

# ---------- 6. 自动运行脚本 ----------
step "6/7 自动运行脚本（marketplaces → plugins → skills → fonts）"
for s in install-marketplaces.sh install-plugins.sh install-git-skills.sh install-fonts.sh; do
  if [ -f "$REPO_ROOT/scripts/$s" ]; then
    echo "  运行 $s ..."
    if bash "$REPO_ROOT/scripts/$s"; then
      ok "  $s 完成"
    else
      warn "  $s 退出码 $?（可稍后重试）"
      pending+=("运行 $s|bash scripts/$s")
    fi
  else
    warn "  缺少 scripts/$s，跳过"
  fi
done

# ---------- CC Switch 导入 ----------
step "导入 CC Switch 配置（providers + 通用配置）"
if [ -f "$REPO_ROOT/scripts/import-cc-switch.py" ]; then
  if command -v python >/dev/null 2>&1; then
    if python "$REPO_ROOT/scripts/import-cc-switch.py"; then
      ok "CC Switch 配置已导入"
    else
      warn "CC Switch 导入失败（可能 .env 未应用或 CC Switch 在运行）"
      pending+=("导入 CC Switch|python scripts/import-cc-switch.py")
    fi
  else
    warn "未找到 python，跳过 CC Switch 导入"
    pending+=("导入 CC Switch|python scripts/import-cc-switch.py")
  fi
fi

# ---------- 7. 验证 ----------
step "7/7 验证安装结果"
allok=true
for cmd in git python node claude; do
  out=$("$cmd" --version 2>&1 | head -1)
  if [ -n "$out" ]; then
    ok "$cmd → $out"
  else
    warn "$cmd → 不可用（可能需要重启终端刷新 PATH）"
    allok=false
    pending+=("安装 $cmd|powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1")
  fi
done

echo ""
echo "--- 配置存在性 ---"
for p in ".gitconfig" ".bashrc" ".claude/CLAUDE.md" ".claude/skills" ".pip/pip.conf" ".npmrc"; do
  if [ -e "$DEST_HOME/$p" ]; then
    ok "$p ✓"
  else
    warn "$p ✗ 未找到"
    allok=false
  fi
done
if ls "$DEST_HOME"/AppData/Local/Microsoft/Windows/Fonts/MapleMono* >/dev/null 2>&1; then
  ok "Maple Mono 字体 ✓"
else
  warn "Maple Mono 字体 ✗ 未安装（可忽略，用默认字体；重试: bash scripts/install-fonts.sh）"
fi

echo ""
if [ "$allok" = true ] && [ ${#pending[@]} -eq 0 ]; then
  echo "==================== 全部完成，环境就绪 ===================="
else
  echo "==================== 完成（有未完成项）===================="
  [ "$allok" = true ] || echo "  - 部分命令/配置不可用：可能软件安装后未重启终端（PATH 未刷新）"
  if [ ${#pending[@]} -gt 0 ]; then
    echo ""
    echo "--- 未完成项 + 重试命令 ---"
    for item in "${pending[@]}"; do
      IFS='|' read -r desc cmd <<< "$item"
      echo "  ⚠ $desc"
      echo "      重试: $cmd"
    done
  fi
fi
