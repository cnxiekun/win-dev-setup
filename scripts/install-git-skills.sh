#!/usr/bin/env bash
# install-git-skills.sh — 安装 git 来源的 Claude skills（clone 后自带 .git，可 git pull 更新）
# 用法: bash scripts/install-git-skills.sh
# 说明: 读取 config/claude/git-skills.json，逐个 git clone 到 ~/.claude/skills/

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
MANIFEST="$REPO_ROOT/config/claude/git-skills.json"

if [ ! -f "$MANIFEST" ]; then
  echo "✗ 未找到 $MANIFEST"
  exit 1
fi

mkdir -p "$SKILLS_DIR"
echo "=== 安装 git 来源的 skills → $SKILLS_DIR ==="

python3 - "$MANIFEST" "$SKILLS_DIR" << 'PYEOF'
import json, subprocess, sys, os
manifest_path, skills_dir = sys.argv[1], sys.argv[2]
with open(manifest_path, encoding='utf-8') as f:
    manifest = json.load(f)

for skill in manifest.get('git_skills', []):
    name = skill['name']
    repo = skill['repo']
    branch = skill.get('branch', 'main')
    target = os.path.join(skills_dir, name)

    if os.path.isdir(os.path.join(target, '.git')):
        print(f"  ✓ {name} 已存在（跳过）")
        continue

    print(f"  正在 clone {name} ...")
    subprocess.run(
        ['git', 'clone', '--branch', branch, repo, target],
        check=True, capture_output=True
    )
    print(f"  ✓ {name} 已安装，可 git pull 更新")

print("\n完成！这些 skill 各自带 .git，可在 ~/.claude/skills/<name>/ 下 git pull 更新")
PYEOF
