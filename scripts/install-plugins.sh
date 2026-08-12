#!/usr/bin/env bash
# install-plugins.sh — 自动安装 Claude Code 插件并设置启用状态
# 用法: bash scripts/install-plugins.sh
# 说明: 安装清单里的全部插件，然后按 plugins.json 的 enabled 状态启用/禁用
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/config/claude/plugins.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "✗ 未找到 claude 命令，请先安装 Claude Code"
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "✗ 未找到 $MANIFEST"
  exit 1
fi

echo "=== 安装 Claude Code 插件 ==="
python - "$MANIFEST" << 'PYEOF'
import json, subprocess, sys
manifest_path = sys.argv[1]
with open(manifest_path, encoding='utf-8') as f:
    plugins = json.load(f)

for p in plugins:
    name = f"{p['plugin']}@{p['marketplace']}"
    enabled = p.get('enabled', True)
    print(f"  安装 {name} ...")
    try:
        r = subprocess.run(['claude.cmd', 'plugin', 'install', name],
                           capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"  ⚠ {name} 安装超时（120s），跳过（可稍后重试）")
        continue
    if r.returncode != 0:
        err = (r.stdout + r.stderr).lower()
        if 'already' not in err:
            print(f"  ✗ {name} 安装失败: {(r.stdout+r.stderr).strip()[:120]}")
            continue
    # 设置启用状态
    if enabled:
        subprocess.run(['claude.cmd', 'plugin', 'enable', name], capture_output=True, timeout=60)
        print(f"  ✓ {name} 已启用")
    else:
        subprocess.run(['claude.cmd', 'plugin', 'disable', name], capture_output=True, timeout=60)
        print(f"  ✓ {name} 已安装（保持禁用）")

print("\n完成！运行 claude plugin list 查看。")
PYEOF
