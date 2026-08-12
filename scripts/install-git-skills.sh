#!/usr/bin/env bash
# install-git-skills.sh — 安装 git 来源的 Claude skills（clone 后自带 .git，可 git pull 更新）
# 用法: bash scripts/install-git-skills.sh
# 说明: 读取 config/claude/git-skills.json
#       幂等：已存在且有 .git → git pull 更新；已存在无 .git → 跳过（不覆盖手动放置的）
#       clone 失败最多重试 3 次（单次 http 超时 60s），全部失败则记入清单并跳过
#       重跑本脚本即可补齐失败的（幂等）

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

python - "$MANIFEST" "$SKILLS_DIR" << 'PYEOF'
import json, subprocess, sys, os, shutil

manifest_path, skills_dir = sys.argv[1], sys.argv[2]
with open(manifest_path, encoding='utf-8') as f:
    manifest = json.load(f)

failures = []
MAX_ATTEMPTS = 3            # 每个 skill clone 最多尝试 3 次
GIT_OPTS = ['-c', 'http.timeout=60']   # 单次 http 超时 60s，避免国内网络卡死

for skill in manifest.get('git_skills', []):
    name = skill['name']
    repo = skill['repo']
    branch = skill.get('branch', 'main')
    target = os.path.join(skills_dir, name)

    # 幂等：已存在且有 .git → git pull 更新（不重复 clone）
    if os.path.isdir(os.path.join(target, '.git')):
        print(f"  → {name} 已存在，git pull 更新 ...")
        r = subprocess.run(['git', '-C', target, 'pull', '--ff-only'],
                           capture_output=True)
        if r.returncode == 0:
            print(f"    ✓ {name} 已更新/已是最新")
        else:
            print(f"    ⚠ {name} pull 失败（可能有本地改动）: "
                  f"{r.stderr.decode(errors='replace').strip()[-200:]}")
            failures.append(name)
        continue

    # 已存在但无 .git：空目录（上次失败残骸）→ 清掉重装；否则跳过不覆盖
    if os.path.exists(target):
        if os.path.isdir(target) and not os.listdir(target):
            os.rmdir(target)
        else:
            print(f"  ⚠ {name} 目录已存在但无 .git，跳过（避免覆盖手动放置的 skill）")
            continue

    print(f"  正在 clone {name} ...")
    ok = False
    for attempt in range(1, MAX_ATTEMPTS + 1):
        r = subprocess.run(['git'] + GIT_OPTS +
                           ['clone', '--branch', branch, repo, target],
                           capture_output=True)
        if r.returncode == 0:
            ok = True
            break
        lines = r.stderr.decode(errors='replace').strip().splitlines()
        detail = lines[-1] if lines else ''
        print(f"    ✗ 第 {attempt}/{MAX_ATTEMPTS} 次尝试失败: {detail[-160:]}")
        # 清理 clone 失败留下的残骸，避免下次 clone 到非空目录
        if os.path.isdir(target):
            shutil.rmtree(target, ignore_errors=True)

    if ok:
        print(f"  ✓ {name} 已安装，可 git pull 更新")
    else:
        print(f"  ✗ {name} 多次尝试均失败，跳过")
        failures.append(name)

print("")
if failures:
    print(f"⚠ 以下 skill 未成功安装/更新：{', '.join(failures)}")
    print("  稍后重试（幂等，已成功的会自动跳过/更新）：bash scripts/install-git-skills.sh")
else:
    print("✓ 全部 skill 就绪，各自带 .git，可在 ~/.claude/skills/<name>/ 下 git pull 更新")
PYEOF
