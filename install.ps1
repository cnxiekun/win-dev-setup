# ============================================================
# win-dev-setup 一键安装（PowerShell 版）
# 用法: irm https://raw.githubusercontent.com/cnxiekun/win-dev-setup/master/install.ps1 | iex
# 作用: 在当前目录拉取仓库 → 交互填写 API key → 配置
#       有 git 则 git clone（可后续更新）；无 git 则下载 zip 解压（一次性）
#       有 bash 则调 setup.sh，无 bash 则调 setup.ps1（先装软件再配置）
# ============================================================
$ErrorActionPreference = 'Continue'
$RepoUrl  = 'https://github.com/cnxiekun/win-dev-setup.git'
$ZipUrl   = 'https://codeload.github.com/cnxiekun/win-dev-setup/zip/refs/heads/master'
$RepoDir  = 'win-dev-setup'

Write-Host "== win-dev-setup 一键安装 ==" -ForegroundColor Cyan

# ---------- 1. 准备仓库 ----------
$haveGit = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
if (Test-Path "$RepoDir\.git") {
    Write-Host "> 检测到已有 $RepoDir，git pull 更新..."
    git -C $RepoDir pull --ff-only
} elseif (Test-Path $RepoDir) {
    Write-Host "✗ $RepoDir 已存在但非 git 仓库，请手动处理后重试。" -ForegroundColor Red
    exit 1
} elseif ($haveGit) {
    Write-Host "> 正在 clone 仓库..."
    git clone $RepoUrl $RepoDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ clone 失败（网络？）。可重试，或改用分步安装。" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "> 未检测到 git，用 zip 下载仓库（装完软件后有 git 后可重新 clone 以便更新）..."
    $zip = Join-Path $env:TEMP 'win-dev-setup.zip'
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
        $unzip = Join-Path $env:TEMP 'win-dev-setup-master'
        if (Test-Path $RepoDir) { Remove-Item $RepoDir -Recurse -Force }
        Move-Item $unzip $RepoDir
        Remove-Item $zip -Force
    } catch {
        Write-Host "✗ 下载仓库失败（网络？）。可重试，或改用分步安装。" -ForegroundColor Red
        exit 1
    }
}
Set-Location $RepoDir

# ---------- 2. 生成 .env（交互填 key）----------
if (-not (Test-Path '.env')) {
    Copy-Item .env.example .env
    Write-Host ""
    Write-Host "> 请填写以下 API key（直接回车跳过，可稍后在 .env 补填后重跑 setup.sh）："
    foreach ($key in @('DEEPSEEK_API_KEY','AGNES_API_KEY','KIMI_API_KEY','TUSHARE_TOKEN','TAVILY_API_KEY')) {
        $val = Read-Host "  $key"
        if ($val) {
            $lines = Get-Content .env -Encoding UTF8 | ForEach-Object {
                if ($_ -match "^$key=") { "$key=$val" } else { $_ }
            }
            # 无 BOM 写入，避免 BOM 破坏 apply-env.sh 对首行注释的解析
            [System.IO.File]::WriteAllLines((Join-Path $PWD '.env'), $lines, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "    ✓ 已填写" -ForegroundColor Green
        }
    }
    Write-Host ""
} else {
    Write-Host "> 已存在 .env，跳过填写（可直接修改 .env）"
}

# ---------- 3. 配置 ----------
$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
if ($bash) {
    Write-Host "> 检测到 Git Bash，用 setup.sh 配置..."
    & $bash "$PWD\scripts\setup.sh"
} else {
    Write-Host "> 未找到 bash，用 setup.ps1（先装软件再配置）..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$PWD\scripts\setup.ps1"
}
