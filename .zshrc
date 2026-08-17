#! /bin/zsh
# VS Code's Shell Integration assumes this var exists.
RPROMPT=''

# Keep PATH entries unique while preserving order.
typeset -U path fpath

path_prepend() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) path=("$1" $path) ;;
  esac
}

path_append() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) path+=("$1") ;;
  esac
}

source_if_readable() {
  [[ -r "$1" ]] && source "$1"
}

# Universal shell init
source_if_readable "$HOME/.shrc"

# User aliases / shared shell snippets.
source_if_readable "$HOME/.bash_aliases"

# Completion search path must be configured before compinit.
[[ -d "$HOME/.zsh/completion" ]] && fpath=("$HOME/.zsh/completion" $fpath)

autoload -Uz compinit zmv

# Completion styling and matching.
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Better SSH/Rsync/SCP autocomplete.
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Case-insensitive completion. Path-prefix backtracking is handled by the
# widget loaded below; generic partial-word matching can rewrite path prefixes.
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

# Initialize completion once. -i ignores insecure completion directories instead of failing.
compinit -i

# allows for unquoted file move arguments
alias mmv='noglob zmv -W'

# History configuration.
setopt EXTENDED_HISTORY          # Store timestamps and command durations.
setopt INC_APPEND_HISTORY        # Write each command immediately.
setopt SHARE_HISTORY             # Share history between sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an immediately repeated command.
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate commands.
setopt HIST_FIND_NO_DUPS         # Do not show previously found duplicate commands.
setopt HIST_IGNORE_SPACE         # Do not record commands starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write duplicate commands to history.
setopt HIST_VERIFY               # Expand history into the line instead of executing immediately.
setopt APPEND_HISTORY            # Append to history instead of overwriting it.

HISTSIZE=1000
SAVEHIST=2000
HISTFILESIZE=2000 # Kept for compatibility with bash-oriented snippets.
if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]]; then
  HISTFILE="$HOME/.zsh_history_${ZELLIJ_SESSION_NAME}"
else
  HISTFILE="$HOME/.zsh_history"
fi

# Platform-specific Java setup. Prefer Java 8 when available, matching the previous config.
if [[ -x /usr/libexec/java_home ]]; then
  if /usr/libexec/java_home -v 1.8 >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
  elif /usr/libexec/java_home >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home)"
  fi
fi

# Common tool paths.
path_append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
path_append "$HOME/.local/bin"

# Optional dotfiles hooks.
source_if_readable "$HOME/.dotfiles/history.sh"

# Homebrew-managed integrations.
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix 2>/dev/null)"
  if [[ -n "$BREW_PREFIX" ]]; then
    source_if_readable "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    source_if_readable "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
  fi
  unset BREW_PREFIX
fi

# bun.
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
source_if_readable "$BUN_INSTALL/_bun"

# fnm.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi

# pnpm.
if [[ "${OSTYPE:-}" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
path_prepend "$PNPM_HOME/bin"
path_prepend "$PNPM_HOME"

# fzf. Some fzf versions warn when restoring the zle option in command-only shells.
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)" 2>/dev/null
fi

# Load after fzf so Tab preserves fzf's explicit ** completion trigger.
source_if_readable "$HOME/.zsh/completion/path-prefix-completion.zsh"

# zellij auto-start.
# if command -v zellij >/dev/null 2>&1; then
#   export XDG_RUNTIME_DIR="/tmp/zellij-$USER"
#   mkdir -p "$XDG_RUNTIME_DIR"
#   chmod 700 "$XDG_RUNTIME_DIR"
#   eval "$(zellij setup --generate-auto-start zsh)"
# fi
