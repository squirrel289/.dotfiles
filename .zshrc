#! /bin/zsh
# VS Code's Shell Integration assumes this var exists.
RPROMPT=''

typeset -U fpath
source_if_readable() { [[ -r "$1" ]] && source "$1"; }

source_if_readable "$HOME/.shrc"
source_if_readable "$HOME/.shell-aliases"

[[ -d "$HOME/.zsh/completion" ]] && fpath=("$HOME/.zsh/completion" $fpath)
autoload -Uz compinit zmv
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
compinit -i

if source_if_readable "$HOME/.shell-integrations"; then
  dotfiles_integrations zsh
fi

alias mmv='noglob zmv -W'
setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS HIST_VERIFY APPEND_HISTORY
HISTSIZE=1000
SAVEHIST=2000
HISTFILESIZE=2000
if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]]; then HISTFILE="$HOME/.zsh_history_${ZELLIJ_SESSION_NAME}"; else HISTFILE="$HOME/.zsh_history"; fi

source_if_readable "$HOME/.dotfiles/history.sh"

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix 2>/dev/null)"
  [[ -n "$BREW_PREFIX" ]] && source_if_readable "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -n "$BREW_PREFIX" ]] && source_if_readable "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
  unset BREW_PREFIX
fi

source_if_readable "$BUN_INSTALL/_bun"
_dotfiles_fnm_zsh="$(dotfiles_generated_target fnm zsh 2>/dev/null)" && [[ -n "$_dotfiles_fnm_zsh" ]] && eval "$_dotfiles_fnm_zsh"
unset _dotfiles_fnm_zsh

source_if_readable "$HOME/.zsh/completion/path-prefix-completion.zsh"

if [[ -z "${ZELLIJ_SESSION_NAME:-}" && -z "${ZELLIJ:-}" ]] && command -v zellij >/dev/null 2>&1; then
  if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    _dotfiles_zellij_runtime_dir="/tmp/zellij-$USER"
    if mkdir -p "$_dotfiles_zellij_runtime_dir" && chmod 700 "$_dotfiles_zellij_runtime_dir"; then
      export XDG_RUNTIME_DIR="$_dotfiles_zellij_runtime_dir"
      _dotfiles_zellij_zsh="$(dotfiles_generated_target zellij zsh 2>/dev/null)" && [[ -n "$_dotfiles_zellij_zsh" ]] && eval "$_dotfiles_zellij_zsh"
    fi
  else
    _dotfiles_zellij_zsh="$(dotfiles_generated_target zellij zsh 2>/dev/null)" && [[ -n "$_dotfiles_zellij_zsh" ]] && eval "$_dotfiles_zellij_zsh"
  fi
fi
unset _dotfiles_zellij_runtime_dir _dotfiles_zellij_zsh
