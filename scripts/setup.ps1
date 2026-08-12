# ============================================================
# win-dev-setup 引导脚本（PowerShell）
# 新电脑初始只有 PowerShell（bash 要装完 Git 才有），所以本脚本只做：
#   1. 提权检查（装软件需要管理员）
#   2. winget 装软件（install-software.ps1）
#   3. 调用 setup.sh（bash）完成所有配置
# 用法: powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
# ============================================================
$ErrorActionPreference = 'Continue'  # 容错：单个步骤失败不中断整体流程
# 本脚本在 scripts/ 下，仓库根是它的父目录
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

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
# WDS_SKIP_INSTALL=1：跳过提权与安装（测试 / 已装好软件的机器只跑配置）
# ============================================================
$skipInstall = ($env:WDS_SKIP_INSTALL -eq '1')
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $skipInstall -and -not $isAdmin) {
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
if ($skipInstall) {
    Write-Warn "WDS_SKIP_INSTALL=1：跳过提权检查与软件安装（仅配置部分）"
} else {
    Write-Ok "以管理员权限运行中"
}

Write-Host "win-dev-setup 开始" -ForegroundColor Magenta

# ---------- 1. 安装软件 ----------
Write-Step "1/2 安装软件（winget 默认路径）"
if ($skipInstall) {
    Write-Ok "跳过软件安装（WDS_SKIP_INSTALL=1）"
} elseif (Test-Path "$RepoRoot\scripts\install-software.ps1") {
    & powershell -ExecutionPolicy Bypass -File "$RepoRoot\scripts\install-software.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "install-software.ps1 退出码 $LASTEXITCODE"
    }
} else {
    Write-Warn "缺少 scripts/install-software.ps1"
}

# ---------- 2. 调用 setup.sh（bash 完成所有配置）----------
Write-Step "2/2 调用 setup.sh（配置全走 bash）"
$bash = Get-BashPath
if ($bash) {
    & $bash "$RepoRoot\scripts\setup.sh"
    exit $LASTEXITCODE
} else {
    Write-Warn "未找到 bash。请先手动安装 Git（winget install Git.Git），然后重新运行 setup.ps1。"
    exit 1
}
