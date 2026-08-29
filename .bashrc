# Bash interactive policy and integrations.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

[ -r "$HOME/.shrc" ] && . "$HOME/.shrc"

HISTCONTROL=ignoreboth:erasedups
_dotfiles_history_sync='history -n; history -w;history -c;history -r;'
case ${PROMPT_COMMAND:-} in
    "$_dotfiles_history_sync"*) ;;
    *) PROMPT_COMMAND="$_dotfiles_history_sync${PROMPT_COMMAND:-}" ;;
esac
unset _dotfiles_history_sync
shopt -s histappend checkwinsize
HISTSIZE=1000
HISTFILESIZE=2000

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
case $TERM in
    xterm-color|*-256color) color_prompt=yes ;;
esac
if [ -n "${force_color_prompt:-}" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then color_prompt=yes; else color_prompt=; fi
fi
if [ "${color_prompt:-}" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt
case $TERM in
    xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1" ;;
esac

USE_COLORS=true
[ -r "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"

if ! shopt -oq posix; then
    if [ -r /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -r /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ -r "$HOME/.shell-integrations" ] && . "$HOME/.shell-integrations"; then
    dotfiles_integrations bash
fi

if command -v nvim >/dev/null 2>&1; then
    alias vim=nvim
fi
if command -v vim >/dev/null 2>&1; then
    alias vi=vim
fi
if command -v tmux >/dev/null 2>&1 && [ -z "${TMUX:-}" ]; then
    tmux attach -t default || tmux new -s default
fi
if command -v zellij >/dev/null 2>&1 && [ -z "${ZELLIJ:-}" ] && [ -z "${ZELLIJ_SESSION_NAME:-}" ]; then
    _dotfiles_zellij_bash=$(dotfiles_generated_target zellij bash 2>/dev/null) && [ -n "$_dotfiles_zellij_bash" ] && eval "$_dotfiles_zellij_bash"
fi
unset _dotfiles_zellij_bash
