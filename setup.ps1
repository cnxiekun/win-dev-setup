# ============================================================
# win-dev-setup 一键配置脚本
# 新电脑环境恢复：装软件 + 拷配置 + 应用 .env
# 用法: powershell -ExecutionPolicy Bypass -File setup.ps1
# ============================================================
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Home = $env:USERPROFILE

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }

Write-Host "win-dev-setup 开始" -ForegroundColor Magenta

# ---------- 1. 安装软件 ----------
Write-Step "1/7 安装软件（winget 默认路径）"
if (Test-Path "$RepoRoot\scripts\install-software.ps1") {
    & powershell -ExecutionPolicy Bypass -File "$RepoRoot\scripts\install-software.ps1"
}

# ---------- 2. 拷 Git 配置 ----------
Write-Step "2/7 配置 Git"
$gitDest = "$Home\.gitconfig"
if (Test-Path "$RepoRoot\config\git\.gitconfig") {
    Copy-Item "$RepoRoot\config\git\.gitconfig" $gitDest -Force
    Write-Ok "已复制 .gitconfig → $gitDest"
} else {
    Write-Warn "缺少 config/git/.gitconfig"
}

# ---------- 3. 拷 Bash 配置 ----------
Write-Step "3/7 配置 Bash（Git Bash 环境）"
foreach ($f in @('.bashrc', '.bash_profile', '.minttyrc')) {
    $src = "$RepoRoot\config\bash\$f"
    if (Test-Path $src) {
        Copy-Item $src "$Home\$f" -Force
        Write-Ok "已复制 $f → ~\$f"
    }
}

# ---------- 4. 拷 Claude 配置 ----------
Write-Step "4/7 配置 Claude Code"
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

# marketplaces（提示用户手动安装，因为需要登录 GitHub）
Write-Ok "marketplaces 清单见 config/claude/marketplaces.json，安装方式："
Write-Ok "  claude plugin marketplace add <owner>/<repo>"

# ---------- 5. 配置国内镜像源 ----------
Write-Step "5/7 配置国内镜像源（pip / npm）"

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
Write-Step "6/7 应用 .env（API keys）"
$envFile = "$RepoRoot\.env"
if (Test-Path $envFile) {
    Write-Ok "检测到 .env，将占位符替换为真实值"
    # 读 .env
    $envMap = @{}
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*(.+)\s*$') {
            $envMap[$matches[1]] = $matches[2]
        }
    }
    # 遍历 config 下所有文件，替换 ${XXX} 占位符
    $files = Get-ChildItem "$RepoRoot\config" -Recurse -File | Where-Object { $_.Extension -ne '.pyc' }
    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $original = $content
        foreach ($key in $envMap.Keys) {
            $placeholder = "\${$key}"
            $content = $content.Replace($placeholder, $envMap[$key])
        }
        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $content, (New-Object System.Text.UTF8Encoding $false))
            Write-Ok "已应用 .env 到 $($file.Name)"
        }
    }
} else {
    Write-Warn "未找到 .env。请复制 .env.example 为 .env 并填写 API keys："
    Write-Warn "  Copy-Item $RepoRoot\.env.example $RepoRoot\.env"
    Write-Warn "  notepad $RepoRoot\.env"
}

# ---------- 7. 自动运行 bash 脚本（marketplaces/plugins/skills/fonts）----------
Write-Step "7/7 自动运行 bash 脚本（marketplaces → plugins → skills → fonts）"

# 定位 bash（Git 装到 C:\Program Files\Git 或默认）
$bash = $null
foreach ($cand in @(
    (Get-Command bash -ErrorAction SilentlyContinue).Source,
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
)) {
    if ($cand -and (Test-Path $cand)) { $bash = $cand; break }
}

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
                Write-Warn "  $s 退出码 $LASTEXITCODE（可手动重试）"
            }
        } else {
            Write-Warn "  $scriptPath 不存在，跳过"
        }
    }
}

Write-Host ""
Write-Host "==================== 完成 ====================" -ForegroundColor Green
Write-Host "剩余手动步骤："
Write-Host "  1. 用 CC Switch 导入 providers.json + common_config.json（GUI）"
Write-Host "  2. 验证: git --version / python --version / node --version / claude --version"
