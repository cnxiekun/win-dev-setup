# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目是什么

Windows 新电脑一键配置环境。把当前机器的 git / bash / Claude Code / CC Switch / wmux / Windows Terminal / 国内镜像源 / 字体配置收集进本仓库（已脱敏），新电脑上克隆后跑一个 `setup.ps1` 全自动恢复环境。远程仓库：`github.com/cnxiekun/win-dev-setup`。

> ⚠️ **区分两个 CLAUDE.md**：`config/claude/CLAUDE.md` 是【要安装到目标机器 `~/.claude/` 的全局 Claude 配置模板】（脱敏版），**不是**本仓库的项目文档。本文件（仓库根目录 `CLAUDE.md`）才是给 Claude Code 在本仓库工作时看的项目文档。

## 核心架构

```
config/   脱敏配置模板 —— 所有真实 API key 一律用 ${KEY} 占位符，安全可提交
.env      本地真实 key（gitignore 排除，永不入库）
.build/   应用 .env 后生成的"已填充"副本（gitignore 排除，永不入库）
install.sh / install.ps1  一键安装：拉仓库→交互填 key→自动配置
scripts/  全部脚本：setup.ps1（PS 引导：提权+装软件+调 setup.sh）、
          setup.sh（bash 配置主脚本）、各 install-*.sh 独立步骤
```

**分工**：新电脑初始只有 PowerShell（bash 要装完 Git 才有），所以 PowerShell 只负责引导装软件，**所有配置逻辑走 bash**（`setup.sh`）。已装好 Git 的机器可直接 `bash scripts/setup.sh`，无需 PowerShell。

**数据流**：`config/` 模板 + `.env` 真实 key →（`apply-env.sh`，由 setup.sh 调用）→ `.build/` 填充副本 → 拷到目标机器。`config/` 永远保持占位符状态，真实 key 只出现在 `.env` 和 `.build/`。

## 关键约定（改代码前必须知道）

1. **脱敏铁律**：真实 key 只能写进 `.env`，`config/` 里永远只放 `${KEY}` 占位符。改完 `config/` 提交前跑 `grep -r "sk-" config/` 自查。
2. **安装顺序**：`scripts/install-software.ps1` 的 `$packages` 数组按安装顺序排列，加软件时保持顺序、补全 `Name / Id / Command` 三字段。Claude Code 现走 winget 原生安装，不依赖 npm/Node。
3. **路径规范**：所有软件用 winget 装默认路径，保持默认即可（winget 默认路径最省心、最可靠，也避免脚本里硬编码路径）。
4. **已装检测**：install-software.ps1 用 `Get-Command` 检测命令是否存在，已装则跳过，不会重复安装。
5. **容错**：`setup.ps1` 用 `$ErrorActionPreference = 'Continue'`，单个步骤失败不中断整体流程。
6. **权限**：非管理员运行时自动 RunAs 提权重启（弹一次 UAC，点「是」）。
7. **CC Switch**：`import-cc-switch.py` 把 `providers.json` / `common_config.json` 直接写回 `~/.cc-switch/cc-switch.db`（sqlite），必须先应用 `.env`（把 `${KEY}` 替换成真实 key）才有意义。

## 常用命令

**一键全自动**（新电脑恢复环境）：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

**分步执行**（单独跑某步 / 调试时）：
```powershell
# 只装软件（winget，已装自动跳过）
powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1
```
```bash
# 配置全流程（bash；setup.ps1 装完软件后也会自动调它）
bash scripts/setup.sh
# 只装 git 来源的 skills（clone 后自带 .git，可 git pull 更新）
bash scripts/install-git-skills.sh
# 只添加 marketplaces（读 config/claude/marketplaces.json）
bash scripts/install-marketplaces.sh
# 只装插件并按 plugins.json 设置启用状态
bash scripts/install-plugins.sh
# 只装 Maple Mono NF CN 字体（默认 v7.9，可带版本参数）
bash scripts/install-fonts.sh [版本]
# 只导入 CC Switch 配置（需先填 .env）
python scripts/import-cc-switch.py
# (bash) 应用 .env 生成 .build/ 填充副本
bash scripts/apply-env.sh
```

## 维护清单（更新时查这张表）

| 要改什么 | 改哪个文件 |
| --- | --- |
| 加 / 换软件 | `scripts/install-software.ps1` 的 `$packages` + README 版本策略表 |
| 加 API key | `.env.example` + 相关 `config/` 模板里放 `${KEY}` 占位符 |
| 加 git 来源 skills | `config/claude/git-skills.json`（install-git-skills.sh 读它） |
| 加本地拷贝 skills | `config/claude/skills/`（setup.ps1 直接拷到 `~/.claude/skills/`） |
| 加 marketplace | `config/claude/marketplaces.json` |
| 加 / 改插件启用状态 | `config/claude/plugins.json`（enabled 字段） |
| 换字体版本 | `scripts/install-fonts.sh` 的 `VERSION` 默认值 |
| Windows Terminal 主题/字体 | `config/windows-terminal/settings.json`（含 Maple Mono 字体引用） |
| 镜像源 | `config/python/pip.conf`（pip 清华源）、`config/node/.npmrc`（npmmirror） |
| Vim 配置 | `config/vim/.vimrc` |
| 终端提示符 | `config/git/git-prompt.sh`（含 \u@\h 动态用户名@主机名） |
| 全局 Claude 行为 | `config/claude/CLAUDE.md`（会被装到目标机器 `~/.claude/`） |

## 当前状态 / 进度

**已完成**：
- [x] 一键脚本 `setup.ps1` 全流程（装软件→配置→镜像源→应用 .env→bash 脚本→CC Switch→验证）
- [x] winget 安装：Git / Python 3.x / Node LTS / Claude Code / wmux，已装检测 + 依赖顺序 + 容错
- [x] 脱敏机制：`.build/` 输出填充副本，`config/` 保持占位符，安全可公开提交
- [x] CC Switch 自动导入（直接写 db）
- [x] 国内镜像源（pip 清华、npm npmmirror）
- [x] Maple Mono NF CN 字体下载安装（默认 v7.9）

**已知坑**：
- 软件装完 PATH 未刷新 → 新开终端再验证；setup.ps1 末尾会提示
- CC Switch 导入失败常见原因：`.env` 未应用，或 CC Switch 正在运行占用 db
- CC Switch 的 skills 同步是**操作驱动**的（只在用户点导入/卸载/切换启用状态时才动文件），不会后台持续覆盖 → **skills 由用户直接维护 `~/.claude/skills/`，不用 CC Switch 管理 skills**；CC Switch 中心的旧记录（`~/.agents/skills/` + db `skills` 表）保留不动即可，不去点它的 Skills 页面就不会干扰

**待办 / 可扩展方向**（未做，供后续继续）：
- 可考虑支持 macOS / WSL 环境（当前仅 Windows + Git Bash）
- 可加 Chrome / 常用开发工具等更多软件到 `$packages`
- 可把 `.env` 的校验前置（缺少必填 key 时提前报错而不是靠 CC Switch 导入失败暴露）
