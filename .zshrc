# VS Code's Shell Integration assumes this var exists
RPROMPT=''

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# taken from https://www.codyhiar.com/blog/zsh-autocomplete-with-ssh-config-file/
# Highlight the current autocomplete option
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Better SSH/Rsync/SCP Autocomplete
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Allow for autocomplete to be case insensitive
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  '+l:|?=** r:|?=**'

# Initialize the autocompletion
autoload -Uz compinit && compinit -i

export JAVA_HOME="$(/usr/libexec/java_home)"

fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit

autoload -Uz zmv
# allows for unquoted file move arguments
alias mmv='noglob zmv -W'

# don't put duplicate lines or lines starting with space in the history.
# Taken from https://github.com/rothgar/mastering-zsh/blob/master/docs/config/history.md
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt APPEND_HISTORY            # append to history file
# setopt HIST_NO_STORE             # Don't store history commands

setopt APPEND_HISTORY            # append to the history file, don't overwrite it

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
HISTFILE=~/.zsh_history_${ZELLIJ_SESSION_NAME}

if [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# Created by `pipx` on 2025-06-14 15:47:41
export PATH="$PATH:/Users/macos/.local/bin"
export JAVA_HOME='/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home'
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

. ~/.dotfiles/history.sh
# bun completions
[ -s "/Users/macos/.bun/_bun" ] && source "/Users/macos/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"


# pnpm
export PNPM_HOME="/Users/macos/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME:$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# fzf
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
# fzf end
eval "$(zellij setup --generate-auto-start zsh)"
if type brew &>/dev/null; then
    local zvm_path="$(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
    if [[ -f "$zvm_path" ]]; then
        source "$zvm_path"
    fi
fi   
