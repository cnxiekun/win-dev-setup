# win-dev-setup

Windows 新电脑一键配置。收集了当前机器的 git / bash / Claude Code / CC Switch / wmux / Windows Terminal 配置（已脱敏），配一键脚本在新电脑恢复环境。

## 覆盖范围

| 类别             | 内容                                 | 位置                         |
| ---------------- | ------------------------------------ | ---------------------------- |
| Git              | user、alias、color、core             | `config/git/.gitconfig`    |
| Bash             | .bashrc、.bash_profile、.minttyrc    | `config/bash/`             |
| Claude Code      | 全局 CLAUDE.md、skills、marketplaces | `config/claude/`           |
| CC Switch        | providers（脱敏，仅第三方）、通用配置 | `config/cc-switch/`        |
| Windows Terminal | settings.json（含 Maple Mono 字体引用）| `config/windows-terminal/` |
| 国内镜像源       | pip 清华源、npm npmmirror            | `config/python/`、`config/node/` |
| 字体             | Maple Mono NF CN（脚本下载安装）      | `scripts/install-fonts.sh` |

> 说明：wmux 配置不备份（新电脑装 wmux 自动生成默认）；.gitconfig 的 mvimdiff/proxy 不备份（本机残留，代理按需手动配）；CC Switch 只备份第三方 provider（DeepSeek/Agnes/Kimi），官方类型自动生成。字体不存文件（~310MB），用脚本从 GitHub 下载。

## 安装规范

所有软件用 **winget 装默认路径**（`C:\Program Files` 等），**禁止自定义盘/中文目录**（`D:\软件` 这种会导致 wmux 编码 bug）。

| 软件        | winget 包                |
| ----------- | ------------------------ |
| Git         | `Git.Git`              |
| Python 3.12 | `Python.Python.3.12`   |
| Node LTS    | `OpenJS.NodeJS.LTS`    |
| Claude Code | `Anthropic.ClaudeCode` |
| wmux        | `openwong2kim.wmux`    |

## 新电脑使用步骤

### 1. 安装前准备

- 已装好 winget（Win10/11 自带，App Installer）
- 已装好 Git for Windows（脚本会装，但先手动装可以更快）

### 2. 一键安装软件

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1
```

### 3. 填写 API keys

```powershell
Copy-Item .env.example .env
notepad .env   # 填 DEEPSEEK_API_KEY / AGNES_API_KEY / KIMI_API_KEY / TUSHARE_TOKEN / TAVILY_API_KEY
```

### 4. 一键配置

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### 5. 自动安装 skills 和 marketplaces

```bash
# 安装 git 来源的 Claude skills（clone 后自带 .git，可 git pull 更新）
bash scripts/install-git-skills.sh
# 清单见 config/claude/git-skills.json（guizang-ppt-skill、stock-analysis）

# 自动添加 Claude Code marketplaces（本质是 git clone，用官方 CLI 自动注册）
bash scripts/install-marketplaces.sh
# 清单见 config/claude/marketplaces.json（10 个）

# 安装 Maple Mono NF CN 字体（开源，从 GitHub Releases 下载 ~152MB）
bash scripts/install-fonts.sh
# 默认 v7.9，可指定版本: bash scripts/install-fonts.sh v7.8

# 安装插件（marketplace 添加后，逐个安装）
claude plugin install <plugin>@<marketplace>

# CC Switch：导入 providers.json + common_config.json（GUI 操作）
# Claude skills：setup.ps1 已拷手动放置的到 ~/.claude/skills/
#   git 来源的（guizang-ppt-skill/stock-analysis）用上面脚本 clone，可 git pull 更新
```

### 6. 验证

```bash
git --version
python --version
node --version
claude --version
```

## 敏感信息说明

- `config/` 里所有 API key 已替换为 `${KEY}` 占位符，**安全可公开/私有提交**
- 真实 key 只存在于你本地的 `.env`（已被 `.gitignore` 排除）
- 提交前可用 `grep -r "sk-" config/` 自查

## 仓库结构

```
win-dev-setup/
├── setup.ps1                  # 主脚本：装软件+拷配置+应用 .env
├── .env.example               # API key 占位符模板
├── .gitignore
├── config/                    # 脱敏配置
│   ├── git/  bash/  claude/  cc-switch/  wmux/  windows-terminal/
└── scripts/
    ├── install-software.ps1   # winget 批量安装
    └── apply-env.sh           # (bash) 应用 .env → .build/
```
