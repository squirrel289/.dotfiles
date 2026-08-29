# Bash-only aliases and functions. Shared aliases remain POSIX-compatible.
[ -r "$HOME/.shell-aliases" ] && . "$HOME/.shell-aliases"

if [ "${USE_COLORS:-}" = true ] && command -v dircolors >/dev/null 2>&1 && ls --color=auto -d . >/dev/null 2>&1; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if command -v brew >/dev/null 2>&1 && command -v fnm >/dev/null 2>&1; then
    _brew_wrapper() {
        command brew "$@"
        local brew_status=$?
        if [[ ( "$1" == upgrade || "$1" == up ) && $brew_status -eq 0 ]]; then
            local node_before node_after newest
            node_before=$(node -v 2>/dev/null || echo none)
            printf '%s\n' '🚀 Checking Node.js via fnm...'
            fnm install --latest
            if sort -V </dev/null >/dev/null 2>&1; then
                newest=$(fnm list | grep -o 'v[0-9.]*' | sort -V | tail -n 1 | sed 's/^v//')
                [ -n "$newest" ] && fnm default "$newest"
            fi
            fnm use default
            node_after=$(node -v 2>/dev/null || echo none)
            [[ "$node_before" == "$node_after" ]] || printf '✅ Node updated from %s to %s\n' "$node_before" "$node_after"
        fi
        return "$brew_status"
    }
    alias brew='_brew_wrapper'
fi
