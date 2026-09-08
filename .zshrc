#! /bin/zsh

# Required once, near the top of ~/.zshrc
autoload -U colors && colors

# VS Code's Shell Integration assumes this var exists.
RPROMPT=''

typeset -U fpath
source_if_readable() { [[ -r "$1" ]] && source "$1"; }

source_if_readable "$HOME/.shrc"
source_if_readable "$HOME/.shell-aliases"

# Load the edit-command-line widget
autoload -Uz edit-command-line
zle -N edit-command-line

# Bind to `v` in Vi command mode (requires set -o vi or bindkey -v)
bindkey -M vicmd v edit-command-line

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

# Keep per-Zellij-session history out of $HOME and remove only our own files
# once Zellij confirms their sessions are no longer active.
_dotfiles_zellij_history_key() {
  print -r -- "${1//[^A-Za-z0-9_.-]/_}"
}

_dotfiles_cleanup_zellij_history() {
  local history_file history_key active_session active_key active_sessions
  local -a active_keys
  local keep
  command -v zellij >/dev/null 2>&1 || return 0
  active_sessions=$(zellij list-sessions --short 2>/dev/null) || return 0
  active_keys=("$1")
  while IFS= read -r active_session; do
    [[ -n "$active_session" ]] && active_keys+=("$(_dotfiles_zellij_history_key "$active_session")")
  done <<< "$active_sessions"

  for history_file in "$2"/history-*(N); do
    history_key=${history_file:t}
    history_key=${history_key#history-}
    keep=false
    for active_key in "${active_keys[@]}"; do
      [[ "$history_key" == "$active_key" ]] && { keep=true; break; }
    done
    [[ "$keep" == true ]] || rm -f -- "$history_file"
  done
}

if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]]; then
  _dotfiles_zellij_history_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/zellij"
  _dotfiles_zellij_history_session="$(_dotfiles_zellij_history_key "$ZELLIJ_SESSION_NAME")"
  if mkdir -p "$_dotfiles_zellij_history_dir" 2>/dev/null && chmod 700 "$_dotfiles_zellij_history_dir" 2>/dev/null; then
    HISTFILE="$_dotfiles_zellij_history_dir/history-$_dotfiles_zellij_history_session"
    _dotfiles_cleanup_zellij_history "$_dotfiles_zellij_history_session" "$_dotfiles_zellij_history_dir"
  else
    HISTFILE="$HOME/.zsh_history"
  fi
  unset _dotfiles_zellij_history_dir _dotfiles_zellij_history_session
else
  HISTFILE="$HOME/.zsh_history"
fi

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

# zsh vi mode customizations
function _vi_mode_indicator() {
  if [[ -n "$ZVM_MODE" ]]; then
    case $ZVM_MODE in
      $ZVM_MODE_NORMAL)      RPS1="%{$fg_bold[green]%}NORMAL%{$reset_color%}" ;;
      $ZVM_MODE_INSERT)      RPS1="%{$fg[cyan]%}INSERT%{$reset_color%}" ;;
      $ZVM_MODE_VISUAL)      RPS1="%{$fg[blue]%}VISUAL%{$reset_color%}" ;;
      $ZVM_MODE_VISUAL_LINE) RPS1="%{$fg[blue]%}V-LINE%{$reset_color%}" ;;
      $ZVM_MODE_REPLACE)     RPS1="%{$fg[yellow]%}REPLACE%{$reset_color%}" ;;
      *)                     RPS1='' ;;
    esac
  else
    case $KEYMAP in
      vicmd)       RPS1="%{$fg_bold[green]%}NORMAL%{$reset_color%}" ;;
      main|viins)  RPS1="%{$fg[cyan]%}INSERT%{$reset_color%}" ;;
      *)           RPS1='' ;;
    esac
  fi
  zle reset-prompt
}

if [[ -n "$ZVM_MODE" ]]; then
  ZVM_VI_HIGHLIGHT_BACKGROUND=blue
  ZVM_VI_HIGHLIGHT_FOREGROUND=white
  ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold
  zvm_after_select_vi_mode() { _vi_mode_indicator; }
else
  function zle-line-init zle-keymap-select { _vi_mode_indicator; }
  zle -N zle-line-init
  zle -N zle-keymap-select
fi
