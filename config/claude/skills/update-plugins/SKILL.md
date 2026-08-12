---
name: update-plugins
description: |
  一键更新所有 Claude Code 插件与 skills。自动发现并更新：
  1. 所有 git 来源的 marketplace 目录（~/.claude/plugins/marketplaces/ 下所有 git 仓库）
  2. 所有已启用的官方插件（通过 claude plugin update 逐个升级）
  3. 所有 git 来源的本地 skills（~/.claude/skills/ 下的 git 仓库）
  4. 所有由 npx skills 安装的 skill（通过 npx skills update -g 更新）
  5. 非 git 目录（手动放置的 skills）自动跳过并提示
  不写死任何插件列表 —— 每次运行都自动扫描当前实际安装的内容，后续新装的插件/skills 也能被覆盖。

  触发场景：用户要求「更新插件」「升级插件」「一键更新 skills」「update plugins」「检查插件更新」等。
metadata:
  trigger: 用户要求更新/升级 Claude Code 插件或 skills
  version: "1.1"
  last_updated: "2026-08-12"
  platform: windows
---

# 一键更新 Claude Code 插件与 Skills

当用户要求「更新插件」「升级插件」时，执行以下自动扫描 + 更新流程。

## 核心原则

**绝不写死插件列表**。每次运行都动态扫描以下位置，发现什么就更新什么。这样用户后续新安装的插件、skills 也会被自动覆盖。

## 更新流程

### 阶段 1：扫描并更新 git 来源的 marketplace

```bash
cd ~/.claude/plugins/marketplaces
for d in */; do
  if [ -d "$d/.git" ]; then
    echo "=== $d ==="
    git -C "$d" pull
  fi
done
```

**注意**：`~/.claude/plugins/marketplaces/` 下的子目录多数是 git 仓库（通过 `/plugin marketplace add` 安装）。遍历所有子目录，只对带 `.git` 的目录执行 `git pull`。

### 阶段 2：刷新 marketplace 目录（官方命令）

```bash
claude plugin marketplace update
```

此命令会刷新所有已注册 marketplace 的目录索引。可能耗时较长（逐个网络请求），超时是正常的，耐心等待。

### 阶段 3：升级所有已启用的插件

```bash
claude plugin list
```

先列出当前已安装的插件及其状态（enabled/disabled）。**只升级 enabled 的插件**，disabled 的跳过（用户明确不用的不折腾）。

逐个执行（`claude plugin update` 不支持 `--all`，只能逐个）：

```bash
claude plugin update "<插件名>@<marketplace名>"
```

对每个 enabled 插件执行，输出「already at the latest version」即已最新，输出「updated from X to Y」即升级成功。

### 阶段 4：更新 git 来源的本地 skills

```bash
cd ~/.claude/skills
for d in */; do
  if [ -d "$d/.git" ]; then
    echo "=== $d ==="
    git -C "$d" pull
  fi
done
```

### 阶段 5：更新 npx skills 安装的 skill

```bash
command -v npx >/dev/null 2>&1 && npx --yes skills update -g
```

`npx skills` 安装的 skill（如 `grill-me`）不是 git 仓库，是 CLI 复制的文件，放在 `~/.agents/skills/` 源目录并符号链接到 `~/.claude/skills/`。它由官方 CLI 管理，必须用 `npx skills update -g` 更新（不能 git pull）。

**注意**：
- 该命令**天然全量扫描**，不写死列表，符合本 skill 原则
- 若机器未装 npx 则静默跳过（`command -v npx` 判断）
- 此命令也会顺带更新其他所有由 npx skills 安装的 skill，不只 grill-me

### 阶段 6：检查非 git 目录（手动 skills）

`~/.claude/skills/` 下非 git 的目录（如 `agnes-image`、`agnes-video` 等手动放置的）无法自动更新，**不要尝试去 git 操作它们**，列出它们并提醒用户：
- 这些是手动放置的，无版本管理
- 若已知来源（如 GitHub），可建议用户手动更新或迁移为 marketplace 插件

## 处理本地修改（重要）

若某个 git 仓库 `git pull` 报冲突，**先检查本地改动是什么**：

```bash
git -C "$d" status --porcelain
```

判断改动来源：
- **官方插件机制自动改的**（如 hooks.json 被清空/删除，通常是插件 enable/disable 留下的）：检查对应插件是否还启用（`claude plugin list`）。若插件未启用，改动无价值，`git checkout -- .` 恢复后 pull。
- **用户自己手改的**：不要覆盖，跳过该仓库并在总结中明确告知，让用户决定。

**原则：不破坏用户本地修改。** 宁可跳过，不要强制覆盖。

## 结束总结

更新完成后向用户报告：
1. 哪些 marketplace 更新了 / 已最新
2. 哪些插件升级了（版本变化） / 已最新
3. 哪些 skills 更新了 / 已最新
4. 哪些无法自动更新（非 git 目录）及原因
5. ⚠️ 提醒：插件更新需要**重启 Claude Code 会话**才生效
