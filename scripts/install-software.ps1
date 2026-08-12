# 新电脑软件一键安装（winget，全部默认路径，按依赖顺序，已装则跳过）
# 用法: powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1

# 权限检测：Git/Python/Node 写 Program Files 需要管理员
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
    .IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "需要管理员权限安装软件（写 Program Files）..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"") `
            -Verb RunAs -Wait
        exit
    } catch {
        Write-Host "✗ 管理员授权被拒绝，无法安装需要管理员权限的软件" -ForegroundColor Red
        exit 1
    }
}

# 容错：单个软件失败不中断后续
$ErrorActionPreference = 'Continue'
Write-Host "=== 检查 winget ===" -ForegroundColor Cyan
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "未找到 winget，请先安装 App Installer（Microsoft Store）"
    exit 1
}

# ============================================================
# 软件清单（按安装顺序排列）
# 各软件相互独立；Node 排在 Claude Code 前（历史经 npm 装需 Node，现 winget 原生装）
# 版本策略：不写死小版本，用主版本（winget 自动取最新稳定）
# ============================================================
$packages = @(
    @{ Name = 'Git';            Id = 'Git.Git';            Command = 'git' },
    @{ Name = 'Python';         Id = 'Python.Python.3';    Command = 'python' },   # 最新 3.x（当前 3.14）
    @{ Name = 'Node.js LTS';    Id = 'OpenJS.NodeJS.LTS';  Command = 'node' },
    @{ Name = 'Claude Code';    Id = 'Anthropic.ClaudeCode'; Command = 'claude' },
    @{ Name = 'wmux';           Id = 'openwong2kim.wmux';  Command = 'wmux' }
)

# ============================================================
# 已装检测：用命令行检查（比 winget list 更快更可靠）
# ============================================================
function Test-Installed {
    param([string]$Cmd)
    if (-not $Cmd) { return $false }
    return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue)
}

foreach ($pkg in $packages) {
    Write-Host ""
    Write-Host "=== $($pkg.Name) ($($pkg.Id)) ===" -ForegroundColor Yellow

    # 检测是否已装（命令可用则跳过）
    if (Test-Installed $pkg.Command) {
        $ver = try { & $pkg.Command --version 2>&1 | Select-Object -First 1 } catch { '' }
        Write-Host "  ✓ 已安装（$ver），跳过" -ForegroundColor Green
        continue
    }

    Write-Host "  安装中..."
    winget install -e --id $pkg.Id --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $($pkg.Name) 安装完成（默认路径）" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $($pkg.Name) 安装失败 (exit=$LASTEXITCODE)，继续下一个" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== 验证 ===" -ForegroundColor Cyan
foreach ($cmd in @('git', 'python', 'node', 'claude')) {
    try {
        $v = & cmd /c "$cmd --version 2>&1"
        Write-Host "  ✓ ${cmd}: $v" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $cmd 不可用，可能需要重启终端" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "安装完成！请重启终端使 PATH 生效。" -ForegroundColor Green
