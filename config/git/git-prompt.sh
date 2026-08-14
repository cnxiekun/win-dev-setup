PS1='\[\033]0;Git Bash Prompt => ~$PWD\007\]' # set window title
PS1="$PS1"'\n'                 # new line
#PS1="$PS1"'\[\033[32m\]'       # change to green
#PS1="$PS1"'\u@\h [\t] '    # user@host<space>
#PS1="$PS1"'\[\033[33m\]'       # change to brownish yellow
#PS1="$PS1"'\w'                 # current working directory
PS1="$PS1"'`a=$?;if [ $a -ne 0 ]; then a="  "$a; echo -ne "\[\e[1A\e[$((COLUMNS-2))G\e[1;90m\e[1;41m${a:(-3)}\]\[\e[0m\e[7m\e[2m\r\n\]";fi`${debian_chroot:+($debian_chroot)}\[\e[1;33m\]\u\[\e[1;31m\]@\[\e[1;35m\]\h\[\e[1;32m\][\t]\[\e[1;31m\]:\[\e[1;36m\]\w'
if test -z "$WINELOADERNOEXEC"
then
  GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
  COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
  COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
  COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
  if test -f "$COMPLETION_PATH/git-prompt.sh"
  then
    . "$COMPLETION_PATH/git-completion.bash"
    . "$COMPLETION_PATH/git-prompt.sh"
    PS1="$PS1"'\[\033[36m\]'  # change color to cyan
    PS1="$PS1"'`__git_ps1`'   # bash function
  fi
fi
#PS1="$PS1"'\[\033[0m\]'        # change color
PS1="$PS1"'\[\e[1;34m\]'
PS1="$PS1"'\n'                 # new line
#PS1="$PS1"'$ '                 # prompt: always $
PS1="$PS1"'\$\[\e[0;39m\] '

MSYS2_PS1="$PS1"               # for detection by MSYS2 SDK's bash.basrc

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
#export GIT_PS1_SHOWUPSTREAM="auto"
#export GIT_PS1_SHOWSTASHSTATE=1


