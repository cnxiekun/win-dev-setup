# win-dev-setup

Windows 新电脑一键配置。收集了当前机器的 git / bash / Claude Code / CC Switch / wmux / Windows Terminal 配置（已脱敏），配一键脚本在新电脑恢复环境。

## 覆盖范围

| 类别             | 内容                                    | 位置                                 |
| ---------------- | --------------------------------------- | ------------------------------------ |
| Git              | user、alias、color、core                | `config/git/.gitconfig`            |
| Bash             | .bashrc、.bash_profile、.minttyrc       | `config/bash/`                     |
| Claude Code      | 全局 CLAUDE.md、skills、marketplaces    | `config/claude/`                   |
| CC Switch        | providers（脱敏，仅第三方）、通用配置   | `config/cc-switch/`                |
| Windows Terminal | settings.json（含 Maple Mono 字体引用） | `config/windows-terminal/`         |
| 国内镜像源       | pip 清华源、npm npmmirror               | `config/python/`、`config/node/` |
| 字体             | Maple Mono NF CN（脚本下载安装）        | `scripts/install-fonts.sh`         |

## 安装规范

所有软件用 **winget 装默认路径**（`C:\Program Files` 等），保持默认最省心、最可靠。

| 软件        | winget 包              | 版本策略 |
| ----------- | ---------------------- | -------- |
| Git         | `Git.Git`            | 最新稳定 |
| Python      | `Python.Python.3`    | **最新 3.x**（不锁死小版本）|
| Node LTS    | `OpenJS.NodeJS.LTS`  | LTS 最新 |
| Claude Code | `Anthropic.ClaudeCode` | 最新    |
| wmux        | `openwong2kim.wmux`    | 最新    |

> **安装顺序**：脚本按清单顺序安装（Git → Python → Node LTS → Claude Code → wmux），各软件相互独立（Claude Code 现走 winget 原生安装，不依赖 npm/Node）。**已装的软件会自动检测跳过**（不会重复安装）。

## 方式 1：一行命令（快速开始）

自动完成：拉取仓库 → 交互填 API key → 配置（装软件 / 镜像源 / 插件 / CC Switch / 验证）。**不用 clone、不用 cd、不用手动建 .env**。

**有 Git Bash：** 打开 Git Bash，粘贴运行：

```bash
curl -fsSL https://raw.githubusercontent.com/cnxiekun/win-dev-setup/master/install.sh | bash
```

**只有 PowerShell：** 打开 PowerShell，粘贴运行：

```powershell
irm https://raw.githubusercontent.com/cnxiekun/win-dev-setup/master/install.ps1 | iex
```

> 运行后会：① 在当前目录创建 `win-dev-setup/`；② 逐个提示你粘贴 5 个 API key（直接回车跳过，可稍后补填）；③ 自动完成配置。装软件会弹一次 UAC，点「是」。
>
> ⚠️ **安全提示**：上面命令会直接执行 `github.com/cnxiekun/win-dev-setup` 上的脚本（公开仓库，可先下载查看）。介意的话用下面的方式 2 分步。
>
> 💡 **网络**：脚本需要访问 GitHub。装了 Clash Verge 等代理时，记得开 **TUN 模式**（或给 git 配 `http.proxy`），否则拉取可能超时。

---

## 方式 2：分步安装（可控）

适合想看清楚每一步做了什么、或方式 1 拉取失败时。下面分步手动完成。

### 分步步骤

**第 1 步：克隆仓库**

打开 **PowerShell**（开始菜单搜 PowerShell），执行：

```powershell
git clone https://github.com/cnxiekun/win-dev-setup.git
cd win-dev-setup
```

> 这一步会在当前目录创建 `win-dev-setup` 文件夹并进入它。后续命令都在这个文件夹里执行。

**第 2 步：填写 API keys**

```powershell
Copy-Item .env.example .env
notepad .env
```

会弹出记事本打开 `.env` 文件，把里面 5 个占位符改成你的真实 key：

| 变量名               | 填什么                                         |
| -------------------- | ---------------------------------------------- |
| `DEEPSEEK_API_KEY` | DeepSeek 平台的 API key（api.deepseek.com）    |
| `AGNES_API_KEY`    | Agnes 平台的 API key（api.agnes-ai.cn）        |
| `KIMI_API_KEY`     | Kimi/月之暗面平台的 API key（api.moonshot.cn） |
| `TUSHARE_TOKEN`    | Tushare 的 token（股票数据）                   |
| `TAVILY_API_KEY`   | Tavily 搜索的 API key                          |

改完保存关闭记事本。

> 💡 `.env` 不是隐藏文件，就在 `win-dev-setup` 文件夹根目录。以后想换 key，直接在文件夹里找到 `.env`，用记事本打开改就行（`notepad .env`）。

**第 3 步：一键配置（二选一）**

先判断：**这台电脑有没有 Git Bash？**（装 Git 时会带上 Git Bash 终端）

- **没有 git bash**（或不确定）→ 用**方式 A**（会自动装软件，需要点一次 UAC）
- **已经有 git bash** → 直接**方式 B**（假设软件已装好，只做配置，不弹 UAC）

> 两条路最终效果一样。区别只是：方式 A 从零开始也能把软件装齐；方式 B 假设你已有 Git 等基础软件，更轻量。

**方式 A：PowerShell 引导（没有 git bash 时）**

在同一个 PowerShell（仍在 `win-dev-setup` 目录里）运行：

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

> 第一次会弹出 UAC 授权窗口（装软件需要管理员权限），点「是」。
> 它先 winget 装 Git/Python/Node/Claude Code/wmux（**已装的自动跳过**），装完自动调用 `setup.sh` 完成全部配置。

**方式 B：直接 bash（已有 git bash 时）**

打开 **Git Bash**，进入 `win-dev-setup` 目录，运行：

```bash
bash setup.sh
```

> 跳过软件安装，只做配置：拷配置 → 镜像源 → 应用 .env → 装 skills/插件 → CC Switch → 验证。不弹 UAC。

**`setup.ps1` / `setup.sh` 分工：**

- **`setup.ps1`（引导）**：提权 + winget 装软件 + 调 `setup.sh`。新电脑初始只有 PowerShell（bash 要装完 Git 才有），所以它是唯一的"从零"入口
- **`setup.sh`（配置，bash）**：拷配置 → 镜像源 → 应用 .env → marketplaces/plugins/skills/fonts → CC Switch → 验证 → 汇总

---

### 分步执行（可选，单独跑某步时）

```powershell
# 只装软件（winget）
powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1
```

```bash
# 配置全流程（bash，已装好 Git 的机器可直接跑；setup.ps1 也会自动调它）
bash setup.sh

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
├── install.ps1                 # 一键安装（PS）：拉仓库+填 key+配置
├── install.sh                  # 一键安装（bash）：拉仓库+填 key+配置
├── setup.ps1                  # 引导脚本：提权 + winget 装软件 + 调 setup.sh
├── setup.sh                   # 配置主脚本（bash）：拷配置+镜像源+.env+插件+CC Switch+验证
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
