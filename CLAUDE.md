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
scripts/  独立步骤脚本（可单独跑，也可被 setup.ps1 串联）
setup.ps1 一键主入口（8 步串起全部：装软件→拷配置→镜像源→应用 .env→跑脚本→导 CC Switch→验证）
```

**数据流**：`config/` 模板 + `.env` 真实 key →（setup.ps1 第 6 步或 `apply-env.sh`）→ `.build/` 填充副本 → 拷到目标机器。`config/` 永远保持占位符状态，真实 key 只出现在 `.env` 和 `.build/`。

## 关键约定（改代码前必须知道）

1. **脱敏铁律**：真实 key 只能写进 `.env`，`config/` 里永远只放 `${KEY}` 占位符。改完 `config/` 提交前跑 `grep -r "sk-" config/` 自查。
2. **依赖顺序**：Node → Claude Code。`scripts/install-software.ps1` 的 `$packages` 数组按依赖顺序排列，加软件时保持顺序、补全 `Name / Id / Command` 三字段。
3. **路径规范**：所有软件用 winget 装默认路径，**禁止自定义盘 / 中文目录**（`D:\软件` 这种会导致 wmux 编码 bug）。
4. **已装检测**：install-software.ps1 用 `Get-Command` 检测命令是否存在，已装则跳过，不会重复安装。
5. **容错**：`setup.ps1` 用 `$ErrorActionPreference = 'Continue'`，单个步骤失败不中断整体流程。
6. **权限**：非管理员运行时自动 RunAs 提权重启（弹一次 UAC，点「是」）。
7. **CC Switch**：`import-cc-switch.py` 把 `providers.json` / `common_config.json` 直接写回 `~/.cc-switch/cc-switch.db`（sqlite），必须先应用 `.env`（把 `${KEY}` 替换成真实 key）才有意义。

## 常用命令

**一键全自动**（新电脑恢复环境）：
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

**分步执行**（单独跑某步 / 调试时）：
```powershell
# 只装软件（winget，已装自动跳过）
powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1
```
```bash
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
- wmux 在中文 / 自定义盘安装路径下会出编码 bug → 安装一律默认路径
- 软件装完 PATH 未刷新 → 新开终端再验证；setup.ps1 末尾会提示
- CC Switch 导入失败常见原因：`.env` 未应用，或 CC Switch 正在运行占用 db

**待办 / 可扩展方向**（未做，供后续继续）：
- 可考虑支持 macOS / WSL 环境（当前仅 Windows + Git Bash）
- 可加 Chrome / 常用开发工具等更多软件到 `$packages`
- 可把 `.env` 的校验前置（缺少必填 key 时提前报错而不是靠 CC Switch 导入失败暴露）
