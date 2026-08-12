# ============================================================
# win-dev-setup 一键配置脚本
# 新电脑环境恢复：装软件 + 拷配置 + 应用 .env
# 用法: powershell -ExecutionPolicy Bypass -File setup.ps1
# ============================================================
$ErrorActionPreference = 'Continue'  # 容错：单个步骤失败不中断整体流程
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Home = $env:USERPROFILE
$pending = @()  # 失败收集：末尾汇总"未完成项 + 重试命令"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }

function Get-BashPath {
    # 定位 bash（Git 装到 C:\Program Files\Git 或默认）
    foreach ($cand in @(
        (Get-Command bash -ErrorAction SilentlyContinue).Source,
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    )) {
        if ($cand -and (Test-Path $cand)) { return $cand }
    }
    return $null
}

# ============================================================
# 权限检测：winget 装软件（写 Program Files）需要管理员权限
# 非管理员时自动用 RunAs 提权重启（触发一次 UAC，用户点"是"）
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
    .IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn "当前非管理员权限。winget 安装软件（写 Program Files）需要管理员权限。"
    Write-Warn "正在请求管理员权限重启... 请在 UAC 弹窗点击「是」。"
    try {
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"") `
            -Verb RunAs -Wait
        exit  # 提权实例执行完毕后，本实例退出
    } catch {
        Write-Host "✗ 管理员授权被拒绝。无法安装需要管理员权限的软件。" -ForegroundColor Red
        Write-Host "  你可以：1) 以管理员身份重新运行 setup.ps1；2) 或单独运行不需要管理员的部分。"
        exit 1
    }
}
Write-Ok "以管理员权限运行中"

Write-Host "win-dev-setup 开始" -ForegroundColor Magenta

# ---------- 1. 安装软件 ----------
Write-Step "1/8 安装软件（winget 默认路径）"
if (Test-Path "$RepoRoot\scripts\install-software.ps1") {
    & powershell -ExecutionPolicy Bypass -File "$RepoRoot\scripts\install-software.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "install-software.ps1 退出码 $LASTEXITCODE"
    }
}

# ---------- 2. 拷 Git 配置 ----------
Write-Step "2/8 配置 Git"
$gitDest = "$Home\.gitconfig"
if (Test-Path "$RepoRoot\config\git\.gitconfig") {
    Copy-Item "$RepoRoot\config\git\.gitconfig" $gitDest -Force
    Write-Ok "已复制 .gitconfig → $gitDest"
} else {
    Write-Warn "缺少 config/git/.gitconfig"
}

# ---------- 3. 拷 Bash 配置 ----------
Write-Step "3/8 配置 Bash（Git Bash 环境）"
foreach ($f in @('.bashrc', '.bash_profile', '.minttyrc')) {
    $src = "$RepoRoot\config\bash\$f"
    if (Test-Path $src) {
        Copy-Item $src "$Home\$f" -Force
        Write-Ok "已复制 $f → ~\$f"
    }
}

# ---------- 4. 拷 Claude 配置 ----------
Write-Step "4/8 配置 Claude Code"
$claudeDir = "$Home\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

# 全局 CLAUDE.md
if (Test-Path "$RepoRoot\config\claude\CLAUDE.md") {
    Copy-Item "$RepoRoot\config\claude\CLAUDE.md" "$claudeDir\CLAUDE.md" -Force
    Write-Ok "已复制全局 CLAUDE.md"
}

# skills
if (Test-Path "$RepoRoot\config\claude\skills") {
    Copy-Item "$RepoRoot\config\claude\skills\*" "$claudeDir\skills\" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "已复制 skills/ → ~/.claude/skills/"
}

# ---------- 5. 配置国内镜像源 ----------
Write-Step "5/8 配置国内镜像源（pip / npm）"

# pip 清华源
$pipDir = "$Home\.pip"
if (Test-Path "$RepoRoot\config\python\pip.conf") {
    if (-not (Test-Path $pipDir)) { New-Item -ItemType Directory -Path $pipDir -Force | Out-Null }
    Copy-Item "$RepoRoot\config\python\pip.conf" "$pipDir\pip.conf" -Force
    Write-Ok "已配置 pip 清华源 → $pipDir\pip.conf"
}

# npm npmmirror 镜像
if (Test-Path "$RepoRoot\config\node\.npmrc") {
    Copy-Item "$RepoRoot\config\node\.npmrc" "$Home\.npmrc" -Force
    Write-Ok "已配置 npm npmmirror 源 → ~\.npmrc"
}

# ---------- 6. 应用 .env（API keys）----------
Write-Step "6/8 应用 .env（API keys）"
# 统一走 apply-env.sh（bash），逻辑单一实现，避免 PowerShell/bash 两份漂移
$envFile = "$RepoRoot\.env"
if (Test-Path $envFile) {
    $bash = Get-BashPath
    if ($bash) {
        & $bash "$RepoRoot\scripts\apply-env.sh"
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "已生成 .build/ 目录（含真实 key，勿 commit）"
        } else {
            Write-Warn "apply-env.sh 应用失败（退出码 $LASTEXITCODE）"
            $pending += @{ step = "应用 .env"; cmd = "bash scripts/apply-env.sh" }
        }
    } else {
        Write-Warn "未找到 bash，跳过 .env 应用"
        $pending += @{ step = "应用 .env"; cmd = "bash scripts/apply-env.sh" }
    }
} else {
    Write-Warn "未找到 .env。请先复制并填写："
    Write-Warn "  Copy-Item $RepoRoot\.env.example $RepoRoot\.env"
    Write-Warn "  notepad $RepoRoot\.env"
    $pending += @{ step = "填写 .env"; cmd = "Copy-Item .env.example .env && notepad .env" }
}

# ---------- 7. 自动运行 bash 脚本（marketplaces/plugins/skills/fonts）----------
Write-Step "7/8 自动运行 bash 脚本（marketplaces → plugins → skills → fonts）"
$bash = Get-BashPath
if (-not $bash) {
    Write-Warn "未找到 bash，跳过脚本运行。请手动执行："
    Write-Warn "  bash scripts/install-marketplaces.sh"
    Write-Warn "  bash scripts/install-plugins.sh"
    Write-Warn "  bash scripts/install-git-skills.sh"
    Write-Warn "  bash scripts/install-fonts.sh"
} else {
    $bashScripts = @(
        'install-marketplaces.sh',
        'install-plugins.sh',
        'install-git-skills.sh',
        'install-fonts.sh'
    )
    foreach ($s in $bashScripts) {
        $scriptPath = "$RepoRoot\scripts\$s"
        if (Test-Path $scriptPath) {
            Write-Ok "运行 $s ..."
            & $bash $scriptPath
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "  $s 完成"
            } else {
                Write-Warn "  $s 退出码 $LASTEXITCODE（可稍后重试）"
                $pending += @{ step = "运行 $s"; cmd = "bash scripts/$s" }
            }
        } else {
            Write-Warn "  $scriptPath 不存在，跳过"
        }
    }
}

# ---------- CC Switch 配置导入 ----------
Write-Ok "导入 CC Switch 配置（providers + 通用配置）..."
$ccSwitchScript = "$RepoRoot\scripts\import-cc-switch.py"
if (Test-Path $ccSwitchScript) {
    # 用 python 直接写 cc-switch.db
    $python = $null
    foreach ($cand in @(
        (Get-Command python -ErrorAction SilentlyContinue).Source,
        "$env:ProgramFiles\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    )) {
        if ($cand -and (Test-Path $cand)) { $python = $cand; break }
    }
    if ($python) {
        & $python $ccSwitchScript
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "  CC Switch 配置已导入"
        } else {
            Write-Warn "  CC Switch 导入失败（可能 .env 未应用或 CC Switch 在运行）"
            $pending += @{ step = "导入 CC Switch 配置"; cmd = "python scripts/import-cc-switch.py" }
        }
    } else {
        Write-Warn "  未找到 python，跳过 CC Switch 导入"
        $pending += @{ step = "导入 CC Switch 配置"; cmd = "python scripts/import-cc-switch.py" }
    }
}

# ---------- 8. 验证安装结果 ----------
Write-Step "8/8 验证安装结果"

function Test-Command {
    param([string]$Name, [string]$Arg)
    try {
        $output = & $Name $Arg 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -and $output) {
            Write-Ok "$Name → $output"
            return $true
        } else {
            Write-Warn "$Name → 不可用（$output）"
            return $false
        }
    } catch {
        Write-Warn "$Name → 不可用（$($_.Exception.Message)）"
        return $false
    }
}

$allOk = $true
$cmdChecks = @(
    @{ name = 'git';    arg = '--version'; retry = 'powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1' },
    @{ name = 'python'; arg = '--version'; retry = 'powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1' },
    @{ name = 'node';   arg = '--version'; retry = 'powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1' },
    @{ name = 'claude'; arg = '--version'; retry = 'powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1' }
)
foreach ($c in $cmdChecks) {
    if (Test-Command $c.name $c.arg) {
        # 命令可用
    } else {
        $allOk = $false
        $pending += @{ step = "安装 $($c.name)"; cmd = $c.retry }
    }
}

# 配置存在性检查（比命令可用性更细一层）
Write-Host ""
Write-Host "--- 配置存在性 ---" -ForegroundColor Cyan
$pathChecks = @(
    @{ desc = "Git 配置";      path = "$Home\.gitconfig" },
    @{ desc = "Bash 配置";     path = "$Home\.bashrc" },
    @{ desc = "Claude 全局配置"; path = "$Home\.claude\CLAUDE.md" },
    @{ desc = "Claude skills"; path = "$Home\.claude\skills" },
    @{ desc = "pip 清华源";    path = "$Home\.pip\pip.conf" },
    @{ desc = "npm 镜像";      path = "$Home\.npmrc" }
)
foreach ($c in $pathChecks) {
    if (Test-Path $c.path) {
        Write-Ok "$($c.desc) ✓"
    } else {
        Write-Warn "$($c.desc) ✗ 未找到"
        $allOk = $false
    }
}
# 字体（Maple Mono，失败可接受——用默认字体）
$mapleFont = Get-ChildItem "$Home\AppData\Local\Microsoft\Windows\Fonts" -Filter "MapleMono*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($mapleFont) {
    Write-Ok "Maple Mono 字体 ✓ ($($mapleFont.Name))"
} else {
    Write-Warn "Maple Mono 字体 ✗ 未安装（可忽略，用默认字体；重试: bash scripts/install-fonts.sh）"
}

Write-Host ""
if ($allOk -and $pending.Count -eq 0) {
    Write-Host "==================== 全部完成，环境就绪 ====================" -ForegroundColor Green
} else {
    Write-Host "==================== 完成（有未完成项）====================" -ForegroundColor Yellow
    if (-not $allOk) {
        Write-Host "  - 部分命令/配置不可用：可能软件安装后未重启终端（PATH 未刷新）"
        Write-Host "  - 处理：新开终端再运行 setup.ps1，或手动检查"
    }
    if ($pending.Count -gt 0) {
        Write-Host ""
        Write-Host "--- 未完成项 + 重试命令 ---" -ForegroundColor Yellow
        foreach ($p in $pending) {
            Write-Host "  ⚠ $($p.step)" -ForegroundColor Yellow
            Write-Host "      重试: $($p.cmd)" -ForegroundColor Cyan
        }
    }
}
