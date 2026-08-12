#!/usr/bin/env bash
# install-marketplaces.sh — 自动安装 Claude Code marketplaces
# 用法: bash scripts/install-marketplaces.sh
# 说明: 读取 config/claude/marketplaces.json，逐个 claude plugin marketplace add
#       本质是 git clone，但用官方 CLI 命令会自动注册到配置
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/config/claude/marketplaces.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "✗ 未找到 claude 命令，请先安装 Claude Code"
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "✗ 未找到 $MANIFEST"
  exit 1
fi

echo "=== 安装 marketplaces ==="
python - "$MANIFEST" << 'PYEOF'
import json, subprocess, sys
manifest_path = sys.argv[1]
with open(manifest_path, encoding='utf-8') as f:
    marketplaces = json.load(f)

for mp in marketplaces:
    name = mp['name']
    # 从 git URL 推导 owner/repo
    url = mp['url']
    # https://github.com/owner/repo.git -> owner/repo
    src = url.rstrip('/')
    if src.endswith('.git'): src = src[:-4]
    src = src.replace('https://github.com/', '')
    print(f"  添加 {name} ({src}) ...")
    # 加超时防止 claude 命令网络卡住无限等待
    try:
        r = subprocess.run(['claude.cmd', 'plugin', 'marketplace', 'add', src],
                           capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"  ⚠ {name} 添加超时（120s），跳过（可稍后重试）")
        continue
    if r.returncode == 0:
        print(f"  ✓ {name} 已添加")
    else:
        # 可能已存在
        if 'already' in (r.stdout + r.stderr).lower():
            print(f"  ~ {name} 已存在（跳过）")
        else:
            print(f"  ✗ {name} 添加失败: {r.stderr.strip()[:100]}")

print("\n完成！")
PYEOF
