#!/bin/zsh
# Start profling:
# zmodload zsh/zprof

local -a precmd_functions

# {{{ setting options

autoload edit-command-line
autoload -U compinit
autoload -U zmv
autoload zcalc

setopt                          \
        append_history          \
        auto_cd                 \
        auto_pushd              \
        chase_links             \
        complete_aliases        \
        extended_glob           \
        extended_history        \
        hist_ignore_all_dups    \
        hist_ignore_dups        \
        hist_ignore_space       \
        hist_reduce_blanks      \
        hist_save_no_dups       \
        hist_verify             \
        ignore_eof              \
        list_types              \
        mark_dirs               \
        noclobber               \
        noflowcontrol           \
        path_dirs               \
        prompt_percent          \
        prompt_subst            \
        rm_star_wait            \
        share_history

# Push a command onto a stack allowing you to run another command first
bindkey '^J' push-line-or-edit

# }}}
# {{{ environment settings

umask 027

extra_path=(
    $HOME/bin \
    $HOME/.nodenv/bin \
    $HOME/.nodenv/shims/ \
    $HOME/.cabal/bin \
    $HOME/.ghcup/bin \
    $HOME/.local/bin \
    /sbin \
    /usr/sbin \
    /usr/local/bin \
    /usr/local/sbin \
)
export PATH="${(j|:|)extra_path}:$PATH"

CDPATH=$CDPATH::$HOME:/usr/local

export MANPATH="$HOME/share/man:${MANPATH}"

PYTHONSTARTUP=$HOME/.pythonrc.py
export PYTHONSTARTUP

# Local development projects go here
SRCDIR=$HOME/src
alias tworkon='SRCDIR=$HOME/tmp djworkon'

HISTFILE=$HOME/.zsh_history
HISTFILESIZE=65536  # search this with `grep | sort -u`
HISTSIZE=4096
SAVEHIST=4096

REPORTTIME=60       # Report time statistics for progs that take more than a minute to run
WATCH=notme         # Report any login/logout of other users
WATCHFMT='%n %a %l from %m at %T.'

# utf-8 in the terminal, will break stuff if your term isn't utf aware
export LANG=en_US.UTF-8
export LC_ALL=$LANG
export LC_COLLATE=C

export EDITOR='vim'
export VISUAL=$EDITOR
export LESS='-imJMWR'
export PAGER="less $LESS"
export MANPAGER=$PAGER
export BROWSER='google-chrome'
export CVSIGNORE='*.swp *.orig *.rej .git'

# Silence Wine debugging output (why isn't this a default?)
export WINEDEBUG=-all
# We pretty much always want 32-bit...
export WINEARCH=win32

# Inline nodenv init to shave a few more ms off the startup time.
# eval "$(nodenv init -)"
export NODENV_SHELL=zsh
source "$HOME/.nodenv/libexec/../completions/nodenv.zsh"
command nodenv rehash 2>/dev/null
nodenv() {
    local command
    command="${1:-}"
    if [ "$#" -gt 0 ]; then
        shift
    fi

    case "$command" in
        rehash|shell)
            eval "$(nodenv "sh-$command" "$@")";;
        *)
            command nodenv "$command" "$@";;
    esac
}

# }}}
# {{{ completions

compinit -C

zstyle ':completion:*' list-colors "$LS_COLORS"

zstyle -e ':completion:*:(ssh|scp|sshfs|ping|telnet|nc|rsync):*' hosts '
    reply=( ${=${${(M)${(f)"$(<~/.ssh/config)"}:#Host*}#Host }:#*\**} )'

# }}}
# {{{ prompt and theme

# Set vi-mode and create a few additional Vim-like mappings
bindkey -v
bindkey "^?" backward-delete-char
bindkey -M vicmd "^R" redo
bindkey -M vicmd "u" undo
bindkey -M vicmd "ga" what-cursor-position
bindkey -M viins '^p' history-beginning-search-backward
bindkey -M vicmd '^p' history-beginning-search-backward
bindkey -M viins '^n' history-beginning-search-forward
bindkey -M vicmd '^n' history-beginning-search-forward

# Allows editing the command line with an external editor
zle -N edit-command-line
bindkey -M vicmd "v" edit-command-line

# Restore bash/emacs defaults.
bindkey '^U' backward-kill-line
bindkey '^Y' yank

# Set up prompt
if [[ ! -n "$ZSHRUN" ]]; then
    source $HOME/.zsh_shouse_prompt

    # Fish shell like syntax highlighting for Zsh:
    # git clone git://github.com/nicoulaj/zsh-syntax-highlighting.git \
    #   $HOME/.zsh-syntax-highlighting/
    if [[ -d $HOME/.zsh-syntax-highlighting/ ]]; then
        source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS+=( brackets pattern )
    fi
fi

# This is a workaround for tmux. When you clear the terminal with ctrl-l
# anything on-screen is not saved (this is compatible with xterm behavior).
# In contrast, GNU screen will first push anything on-screen into the
# scrollback buffer before clearing the screen which I prefer.
function tmux-clear-screen() {
    for line in {1..$(( $LINES ))} ; do echo; done
    zle clear-screen
}
zle -N tmux-clear-screen
bindkey "^L" tmux-clear-screen

# }}}
# {{{ aliases

alias zmv='noglob zmv'
# e.g., zmv *.JPEG *.jpg

alias ls='ls -F --color'
alias la='ls -A'; compdef la=ls
alias ll='ls -lh'; compdef ll=ls
alias lls='ll -Sr'; compdef lls=ls

alias vi=$EDITOR; compdef vi=vim
# fast Vim that doesn't load a vimrc or plugins
alias vv=$EDITOR' -N -u NONE'; compdef vv=vim
# Loads vimrc but no plugins
alias vvv=$EDITOR' -N --noplugin'; compdef vvv=vim

alias vimprof=$EDITOR' \
    --cmd "profile start vim-profile.log" \
    --cmd "profile func *" \
    --cmd "profile file *"'

compdef c=curl

alias less='less -imJMW'
alias cls='clear' # note: ctrl-L under zsh does something similar
alias ducks='du -cks * | sort -rn | head -15'
alias tree="tree -FC --charset=ascii"
alias info='info --vi-keys'
alias wtf='wtf -o'
alias nnn='nnn -S'
alias clip='xclip -selection clipboard'
alias ocaml='rlwrap ocaml'
alias rs='rsync -avhzC --progress'
compdef rs=rsync
alias mplayer='mplayer -af scaletempo -speed 1'

# Print all files under the current path without prefixed path.
# Useful for listing files under one path based on the files in another. E.g.:
# cd /path/to/dotfiles; filesunder | xargs -0 -I@ ls -l $HOME/@
alias filesunder='find . \( -name .git -type d \) -prune -o -type f -printf "%P\0"'
alias filesmissing='find . -maxdepth 2 -xtype l'

# Quickly ssh through a bastian host without having to hard-code in ~/.ssh/config
alias pssh='ssh -o "ProxyCommand ssh $PSSH_HOST nc -w1 %h %p"'

# Useful for working with Git remotes; e.g., ``git log IN``
alias -g IN='..@{u}'
alias -g IIN='...@{u}'
alias -g OUT='@{u}..'
alias -g OOUT='@{u}...'
alias -g UP='@{u}'

# Don't prompt to save when exiting R
alias R='R --no-save'

# Selects a random file: ``mplayer RANDOM``
alias -g RANDOM='"$(shuf -e -n1 *)"'

# Output stderr in red. Usage: somecomand RED
alias -g RED='2> >(while read line; do echo -e "\e[01;31m$line\e[0m" >&2; done)'

# trailing space helps sudo recognize aliases
# breaks if flags are given (e.g. sudo -u someuser vi /etc/hosts)
alias sudo='command sudo '

# Drop-in for quick notifications. E.g., sleep 10; lmk
alias lmk='notify-send "Task in $(basename $(pwd)) is done"\
    "Task in $(basename $(pwd)) is done"'

# }}}
# Miscellaneous Functions:
# error Quickly output a message and exit with a return code {{{1
function error() {
    EXIT=$1 ; MSG=${2:-"$NAME: Unknown Error"}
    [[ $EXIT -eq 0 ]] && echo $MSG || echo $MSG 1>&2
    return $EXIT
}

# }}}
# zshrun A lightweight, one-off application launcher {{{1
# by Mikael Magnusson (I think)
#
# To run a command without closing the dialog press ctrl-j instead of enter
# Invoke like:
# sh -c 'ZSHRUN=1 uxterm -geometry 100x4+0+0 +ls'

if [[ -n "$ZSHRUN" ]]; then
    unsetopt ignore_eof
    unset ZSHRUN

    function _accept_and_quit() {
        zsh -c "${BUFFER}" &|
        exit
    }
    zle -N _accept_and_quit
    bindkey "^J" accept-line
    bindkey "^M" _accept_and_quit
    PROMPT="zshrun %~> "
    RPROMPT=""
fi

# }}}
# ...() Open fuzzy-finder of parent directory names {{{1

alias ..='cd ..'
function ...() {
    explode_path | tail -n +2 | pick | read -d -r new_dir
    cd "$new_dir"
}

# }}}
# cdd() Open fuzzy-finder of child directory names {{{1

function cdd() {
    ffind . -type d | pick | read -d -r new_dir
    cd "$new_dir"
}

# Same thing but open with nnn instead of cd'ing.
function nnnn() {
    ffind "${1:-$PWD}" -type d | pick | read -d -r new_dir
    nnn "$new_dir"
}

# }}}
# 256-colors test {{{

256test()
{
    echo -e "\e[38;5;196mred\e[38;5;46mgreen\e[38;5;21mblue\e[0m"
}

# }}}
# Dictionary lookup {{{1
# Many more options, see:
# http://linuxcommando.blogspot.com/2007/10/dictionary-lookup-via-command-line.html

dict (){
    curl 'dict://dict.org/d:$1:*'
}

spell (){
    echo $1 | aspell -a
}

# }}}
# Output total memory currently in use by you {{{1

memtotaller() {
    /bin/ps -u $(whoami) -o pid,rss,command |\
        awk '{sum+=$2} END {print "Total " sum / 1024 " MB"}'
}

# Output total memory in use by all children processes
memchildren() {
    ps -h -o pid --ppid $1 |\
        xargs printf "/proc/%s/smaps\n" |\
        xargs awk '/^Pss/ { total += $2 } END { print "Total " total / 1024 " KB" }'
}

# }}}
# xssh {{{1
# Paralelize running shell commands through ssh on multiple hosts with xargs
#
# Usage:
#   echo uptime | xssh host1 host2 host3
#
# Usage:
#   xssh host1 host2 host3
#   # prompts for commands; ctrl-d to finish
#   free -m | awk '/^-/ { print $4, "MB" }'
#   uptime
#   ^d

function xssh() {
    local HOSTS="${argv}"
    [[ -n "${HOSTS}" ]] || return 1

    local tmpfile="/tmp/xssh.cmd.$$.$RANDOM"
    trap 'rm -f '$tmpfile'; return;' EXIT

    # Grab the command(s) from stdin and write to tmpfile
    cat - > ${tmpfile}

    # Execute up to 5 ssh processes at a time and pipe tmpfile to the stdin of
    # the remote shell
    echo -n "${HOSTS[@]}" | xargs -d" " -P5 -IHOST \
        sh -c 'ssh -T HOST < '${tmpfile}' | sed -e "s/^/HOST: /g"'
}
compdef xssh=ssh

# }}}
# wait_for_ssh {{{1
# Block until a multiplexed ssh connection is ready
#
# Useful for making a single ssh connection that can be reused for many ssh
# operations. This requires ControlMaster and ControlPath to be configured in
# your ~/.ssh/config file.
#
# Usage:
#   SSH="me@example.com"
#   trap 'ssh -O exit '${SSH} SIGINT SIGTERM EXIT
#   ssh -N ${SSH} &
#   _wait_for_ssh ${SSH}
#   ...use multiplexed ssh connection here...

function _wait_for_ssh () {
    local ssh="${1?:ssh hostname required}"

    printf 'Connecting to "%s".\n' "$ssh"
    while ! ssh -O check ${ssh} &>/dev/null true; do
        printf '.' ; sleep 0.5;
    done
    printf '\nConnected!\n'
}

# }}}
# fetchall {{{1
# Run git fetch on all repos under the current dir

function fetchall () {
    find . -type d -name .git -print0 \
        | xargs -t -r -0 -P5 -I@ git --git-dir=@ fetch -a
}

function ssh_fetchall () {
    setopt LOCAL_OPTIONS NO_MONITOR
    local SSH_URI="${1:?SSH connection string required.}"

    # Start a connection and wait for it; exit when we're done
    trap 'ssh -O exit '${SSH_URI} SIGINT SIGTERM EXIT
    ssh -N ${SSH_URI} &
    _wait_for_ssh ${SSH_URI}

    # Kick off a ton of parallel fetch operations
    time fetchall

    local count=$(find . -type d -name .git -print | wc -l)
    printf 'Fetched upstream changes for %s repositories.\n' "$count"
}

alias fetchall-gh='ssh_fetchall "git@github.com"'
alias fetchall-gl='ssh_fetchall "git@gitlab.com"'

# }}}
# presentation_mode {{{1
# Set various settings and open a new xterm window for giving presentations

function presentation_mode() {
    (PRESENTATION_MODE=1 xterm -fg black -bg white -fs 16 &>/dev/null &)
}

# }}}
# countdown & timer {{{1
# (Ab)use prompt escapes to get the time without spawning a subshell. :)

function countdown() {
    local now remaining
    local epoch='%D{%s}'
    local target=$(( ${(%)epoch} + $1 ))

    while true; do
        now=${(%)epoch}
        remaining=$(( target - now ))

        if (( $remaining > 0 )) ; then
            printf '\rT-minus: %3d' "${remaining}"
            sleep 1
        else
            printf '\a\n'
            break
        fi
    done
}

alias tea-timer="countdown 120 && notify-send 'Tea!' 'Tea is done.'"

function _timer_elapsed() {
    local epoch='%D{%s}'
    local start=$1
    local end=${(%)epoch}

    printf '%d\n' "$(( end - start ))"
}

function timer() {
    local dts='%D{%H:%M:%S}'
    local epoch='%D{%s}'
    local start=${(%)epoch}

    trap 'printf '\''\nTime elapsed: %d seconds\n'\'' \
        "$(_timer_elapsed '"$start"')"; return;' INT

    printf 'Starting timer at %s\n' "${(%)dts}"
    while true; do 
        printf '\r%4d seconds' "$(_timer_elapsed "$start")"
        sleep 1
    done
}

# }}}
# ztail {{{1
# Run a command then open two tmux panes to tail stdout and stderr separately.

function ztail() {
    unsetopt noclobber

    trap '
        excode=$?; trap - EXIT;
        rm -f /tmp/ztail.{out,err}
        return
    ' INT TERM EXIT QUIT

    touch /tmp/ztail.out /tmp/ztail.err
    tmux splitw 'less +F /tmp/ztail.out'
    tmux splitw -v 'less +F /tmp/ztail.err'

    "$@" 1>/tmp/ztail.out 2>/tmp/ztail.err
}

# }}}
# curlretry {{{1
# Repeatedly download & resume from a URL until finished;
# useful for bad connections.

function curlretry() {
    local url=$1
    local fname=$2
    until curl -L -C - -g "${url}" -o "${fname}"; do echo Retrying && sleep 1; done
}

### }}}

# Run precmd functions
precmd_functions=( precmd_prompt )

if [[ -r "$HOME/.zsh_customize" ]]; then
    source "$HOME/.zsh_customize"
fi

# End profiling:
# zprof

# EOF
