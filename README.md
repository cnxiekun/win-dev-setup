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

### 一键操作（推荐）

克隆仓库后，**先填 .env，再一条命令完成全部**：

```powershell
Copy-Item .env.example .env
notepad .env   # 填 DEEPSEEK_API_KEY / AGNES_API_KEY / KIMI_API_KEY / TUSHARE_TOKEN / TAVILY_API_KEY

powershell -ExecutionPolicy Bypass -File setup.ps1
```

setup.ps1 自动串联：
1. winget 装软件（Git/Python/Node/Claude Code/wmux）
2. 配置 Git / Bash / Claude / 镜像源
3. 应用 .env
4. 自动运行 install-marketplaces.sh → install-plugins.sh → install-git-skills.sh → install-fonts.sh
5. 自动导入 CC Switch 配置（providers + 通用配置）

---

### 分步执行（可选，单独跑某步时）

```powershell
# 只装软件（winget）
powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1
```

```bash
# 只装 git 来源的 skills（clone 后自带 .git，可 git pull 更新）
bash scripts/install-git-skills.sh

# 只添加 marketplaces（10 个）
bash scripts/install-marketplaces.sh

# 只装插件（15 个，按清单设置启用状态）
bash scripts/install-plugins.sh

# 只装 Maple Mono NF CN 字体（默认 v7.9）
bash scripts/install-fonts.sh

# 只导入 CC Switch 配置（需先填 .env）
python scripts/import-cc-switch.py
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
│   ├── git/  bash/  claude/  cc-switch/  windows-terminal/
└── scripts/
    ├── install-software.ps1   # winget 批量安装
    ├── install-marketplaces.sh # 添加 marketplaces
    ├── install-plugins.sh     # 安装插件
    ├── install-git-skills.sh  # clone git skills
    ├── install-fonts.sh       # 安装 Maple Mono 字体
    ├── import-cc-switch.py    # 导入 CC Switch 配置
    └── apply-env.sh           # (bash) 应用 .env → .build/
```
