# 新电脑软件一键安装（winget，全部默认路径）
# 用法: powershell -ExecutionPolicy Bypass -File scripts/install-software.ps1

$ErrorActionPreference = 'Stop'
Write-Host "=== 检查 winget ===" -ForegroundColor Cyan
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "未找到 winget，请先安装 App Installer（Microsoft Store）"
    exit 1
}

$packages = @(
    @{ Name = 'Git';            Id = 'Git.Git' },
    @{ Name = 'Python 3.12';    Id = 'Python.Python.3.12' },
    @{ Name = 'Node.js LTS';    Id = 'OpenJS.NodeJS.LTS' },
    @{ Name = 'Claude Code';    Id = 'Anthropic.ClaudeCode' },
    @{ Name = 'wmux';           Id = 'openwong2kim.wmux' }
)

foreach ($pkg in $packages) {
    Write-Host ""
    Write-Host "=== 安装 $($pkg.Name) ($($pkg.Id)) ===" -ForegroundColor Yellow
    winget install -e --id $pkg.Id --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $($pkg.Name) 安装完成（默认路径）" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $($pkg.Name) 安装可能未完成 (exit=$LASTEXITCODE)，请手动检查" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== 验证 ===" -ForegroundColor Cyan
foreach ($cmd in @(@{N='git'; C='git --version'}, @{N='python'; C='python --version'}, @{N='node'; C='node --version'})) {
    try {
        $v = & cmd /c "$($cmd.C) 2>&1"
        Write-Host "  ✓ $($cmd.N): $v" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $($cmd.N) 不可用，可能需要重启终端" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "安装完成！请重启终端使 PATH 生效。" -ForegroundColor Green
