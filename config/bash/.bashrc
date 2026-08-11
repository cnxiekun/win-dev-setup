# LS color
LS_COLORS="di=1;4;34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:"
export LS_COLORS
export LSCOLORS="exfxcxdxbxGxDxabagacad"

# ================== Alias ==================

# PS
alias psa="ps aux"
alias psg="ps aux | grep "

# Show human friendly numbers and colors
alias df='df -h'
alias du='du -h -d 2'

alias ll='ls -lh --color=auto'
alias ls='ls --color=auto -C'
alias l.='ls -d .[!.]* ..?* --color=auto -lh 2>/dev/null; true'

# 自动获取终端列宽（wmux 等环境 COLUMNS 未传时）
if [ -z "$COLUMNS" ] && command -v tput >/dev/null 2>&1; then
  export COLUMNS=$(tput cols 2>/dev/null || echo 80)
fi

# show me files matching "ls grep"
alias lsg='ll | grep'

alias be='vim ~/.bashrc' #bashrc edit
alias br='source ~/.bashrc'  #bashrc reload
alias ve='vim ~/.vimrc' #vimrc edit
alias vr='source ~/.vimrc'  #vimrc reload
alias ge='vim ~/.config/git/git-prompt.sh' #git-prompt edit
alias gr='source ~/.config/git/git-prompt.sh'  #git-prompt reload
alias ce='vim ~/.claude/settings.json'

# mimic vim functions
alias :q='exit'

# Git Aliases
alias gs='git status'
alias gstsh='git stash'
alias gst='git stash'
alias gsp='git stash pop'
alias gsa='git stash apply'
alias gsh='git show'
alias gshw='git show'
alias gshow='git show'
alias gi='vim .gitignore'
alias gcm='git ci -m'
alias gcim='git ci -m'
alias gci='git ci'
alias gco='git co'
alias gcp='git cp'
alias ga='git add -A'
alias gap='git add -p'
alias guns='git unstage'
alias gunc='git uncommit'
alias gm='git merge'
alias gms='git merge --squash'
alias gam='git amend --reset-author'
alias grv='git remote -v'
alias grr='git remote rm'
alias grad='git remote add'
alias gr='git rebase'
alias gra='git rebase --abort'
alias ggrc='git rebase --continue'
alias gbi='git rebase --interactive'
alias gl='git l'
alias glg='git l'
alias glog='git l'
alias co='git co'
alias gf='git fetch'
alias gfp='git fetch --prune'
alias gfa='git fetch --all'
alias gfap='git fetch --all --prune'
alias gfch='git fetch'
alias gd='git diff'
alias gb='git b'
# Staged and cached are the same thing
alias gdc='git diff --cached -w'
alias gds='git diff --staged -w'
alias gpub='grb publish'
alias gtr='grb track'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gps='git push'
alias gpsh='git push -u origin `git rev-parse --abbrev-ref HEAD`'
alias gnb='git nb' # new branch aka checkout -b
alias grs='git reset'
alias grsh='git reset --hard'
alias gcln='git clean'
alias gclndf='git clean -df'
alias gclndfx='git clean -dfx'
alias gsm='git submodule'
alias gsmi='git submodule init'
alias gsmu='git submodule update'
alias gt='git t'
alias gbg='git bisect good'
alias gbb='git bisect bad'
alias gdmb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'

# Common shell functions
alias less='less -r'
alias tf='tail -f'
alias l='less'
alias lh='ls -alt | head' # see the last modified files
alias screen='TERM=screen screen'
alias cl='clear'
alias cc='claude'
alias ccr='claude --resume'

# Zippin
alias gz='tar -zcvf'

alias ka9='killall -9'
alias k9='kill -9'

alias ..='cd ..'

# VS Code (winget 默认路径优先，回退到常见位置)
if [ -f "$LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe" ]; then
  alias code='"$LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe"'
elif [ -f "/c/Program Files/Microsoft VS Code/Code.exe" ]; then
  alias code='"/c/Program Files/Microsoft VS Code/Code.exe"'
fi

# btop (系统监控, winget 安装, 可执行文件名为 btop4win)
alias btop='btop4win'

export MSYS=enable_pcon

# 个人项目快捷目录（按需修改）
alias pro='cd /d/Personal/Projects'

# npm global bin (Claude Code 等) — 动态检测用户目录
export PATH="$HOME/AppData/Roaming/npm:$PATH"

# pipx 安装的应用 (pylsp 等)
export PATH="$HOME/.local/bin:$PATH"

# 强制 UTF-8 编码，解决中文乱码（wmux/Windows Terminal 等环境）
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
