# ============================================================
# .bashrc — Git Bash 配置
# ============================================================

# ============================================================
# 1. 环境变量（编码 / PATH / 终端）
# ============================================================

# 强制 UTF-8 编码，解决中文乱码（wmux/Windows Terminal 等环境）
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

# PATH 追加：npm global bin（Claude Code 等）— 动态检测用户目录
export PATH="$HOME/AppData/Roaming/npm:$PATH"
# PATH 追加：pipx 安装的应用（pylsp 等）
export PATH="$HOME/.local/bin:$PATH"

# MSYS 伪控制台：让 Git Bash 里跑的 Windows 原生命令行程序（python/node REPL 等）
# 获得正确的终端交互（颜色/光标/全屏刷新），代替旧的 winpty 方案
export MSYS=enable_pcon

# LS 颜色
LS_COLORS="di=1;4;34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:tw=32;40;07:ow=33;40;07:"
export LS_COLORS
export LSCOLORS="exfxcxdxbxGxDxabagacad"

# 自动获取终端列宽（wmux 等环境 COLUMNS 未传时）
if [ -z "$COLUMNS" ] && command -v tput >/dev/null 2>&1; then
  export COLUMNS=$(tput cols 2>/dev/null || echo 80)
fi

# ============================================================
# 2. 文件与目录
# ============================================================

# --- 列表 ---
alias ls='ls --color=auto -C'
alias ll='ls -lh --color=auto'
alias l.='ls -d .[!.]* ..?* --color=auto -lh 2>/dev/null; true'
alias lh='ls -alt | head'    # 最近修改的文件
alias l='less'
alias less='less -r'

# --- 目录 ---
alias ..='cd ..'

# --- 搜索 / 查看 ---
alias lsg='ll | grep'        # 按名搜索文件
alias tf='tail -f'           # 跟踪文件
alias cl='clear'             # 清屏

# --- 压缩 ---
alias gz='tar -zcvf'

# ============================================================
# 3. 编辑器与配置编辑（edit + reload 配对）
# ============================================================
alias be='vim ~/.bashrc'                     # bashrc edit
alias br='source ~/.bashrc'                  # bashrc reload
alias ve='vim ~/.vimrc'                      # vimrc edit
alias vr='source ~/.vimrc'                   # vimrc reload
alias ge='vim ~/.config/git/git-prompt.sh'   # git-prompt edit
alias gr='source ~/.config/git/git-prompt.sh' # git-prompt reload
alias ce='vim ~/.claude/settings.json'

# ============================================================
# 4. 系统 / 进程 / 监控
# ============================================================
alias psa="ps aux"
alias psg="ps aux | grep "
alias df='df -h'
alias du='du -h -d 2'
alias ka9='killall -9'
alias k9='kill -9'
alias btop='btop4win'        # 系统监控（winget 安装，可执行文件名为 btop4win）
alias :q='exit'              # mimic vim functions

# ============================================================
# 5. Git
# ============================================================
# --- 状态 / 暂存 / 提交 ---
alias gs='git status'
alias ga='git add -A'
alias gap='git add -p'
alias gi='vim .gitignore'
alias gcm='git ci -m'
alias gcim='git ci -m'
alias gci='git ci'
alias gam='git amend --reset-author'
alias guns='git unstage'
alias gunc='git uncommit'

# --- 查看 / 日志 / 差异 ---
alias gsh='git show'
alias gshw='git show'
alias gshow='git show'
alias gl='git l'
alias glg='git l'
alias glog='git l'
alias gd='git diff'
# Staged and cached are the same thing
alias gdc='git diff --cached -w'
alias gds='git diff --staged -w'

# --- 分支 / 切换 ---
alias gb='git b'
alias gnb='git nb'           # new branch aka checkout -b
alias gco='git co'
alias co='git co'
alias gdmb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'

# --- 合并 / 变基 / cherry-pick ---
alias gm='git merge'
alias gms='git merge --squash'
alias gr='git rebase'
alias gra='git rebase --abort'
alias ggrc='git rebase --continue'
alias gbi='git rebase --interactive'
alias gcp='git cp'

# --- 远程 / 拉取 / 推送 ---
alias grv='git remote -v'
alias grr='git remote rm'
alias grad='git remote add'
alias gf='git fetch'
alias gfp='git fetch --prune'
alias gfa='git fetch --all'
alias gfap='git fetch --all --prune'
alias gfch='git fetch'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gps='git push'
alias gpsh='git push -u origin `git rev-parse --abbrev-ref HEAD`'
alias gpub='grb publish'
alias gtr='grb track'

# --- stash / reset / clean ---
alias gstsh='git stash'
alias gst='git stash'
alias gsp='git stash pop'
alias gsa='git stash apply'
alias grs='git reset'
alias grsh='git reset --hard'
alias gcln='git clean'
alias gclndf='git clean -df'
alias gclndfx='git clean -dfx'

# --- submodule / bisect / tag ---
alias gsm='git submodule'
alias gsmi='git submodule init'
alias gsmu='git submodule update'
alias gbg='git bisect good'
alias gbb='git bisect bad'
alias gt='git t'

# ============================================================
# 6. Claude Code
# ============================================================
alias cc='claude'               # 新会话
alias ccc='claude --continue'   # 继续最近
alias ccr='claude --resume'     # 历史会话选择

# ============================================================
# 7. 应用快捷
# ============================================================

# VS Code（winget 默认路径优先，回退到常见位置）
if [ -f "$LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe" ]; then
  alias code='"$LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe"'
elif [ -f "/c/Program Files/Microsoft VS Code/Code.exe" ]; then
  alias code='"/c/Program Files/Microsoft VS Code/Code.exe"'
fi

# 个人项目快捷目录（按需修改）
alias pro='cd /d/Personal/Projects'
