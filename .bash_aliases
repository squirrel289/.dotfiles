# enable color support of ls and also add handy aliases
if $USE_COLORS && [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

alias m4b-tool='podman run -it --rm -u $(id -u):$(id -g) -v /mnt/data/downloads/completed/book:/mnt sandreas/m4b-tool:latest'

# Shortcuts for docker compose
dc() {
  cur=`pwd`
  cd "$1" && docker-compose ${@:2} || true
  cd "$cur"
}

dcud() {
  dc $1 up -d ${@:2}
}

dcp() {
  dc $1 pull ${@:2}
}

dct() {
  dc $1 logs --tail 100 ${@:2}
}

# shorthand aliases for everyday apps
alias s='ssh'
alias g='git'
alias get_id='openssl rand -hex '

if command -v podman &> /dev/null && ! command -v docker &> /dev/null; then
  alias docker=podman
fi

if command -v code &> /dev/null && ! command -v vs &> /dev/null; then
  alias vs=code
fi

if_dirty_git_worktree() {
    # Check if current directory is a git repo and if it is dirty
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        if [[ -n "$(git status --porcelain)" ]]; then
            # Execute the command if dirty
            "$@"
        else
            echo "Repository is clean. Nothing to do..." >&2
        fi
    else
        echo "Not in a Git repository. Abortng..." >&2
    fi
}

if command -v pi &> /dev/null && ! command -v commit &> /dev/null; then
  alias commit='if_dirty_git_worktree pi -p "review and commit the local changes in coherent, atomic, independent sets with a commitlint-compliant message and detailed bullets"'
fi

# if brew AND fnm exist, wrap brew with a convenience script to update system node default
if command -v brew &> /dev/null && command -v fnm &> /dev/null; then
  _brew_wrapper() {
    # If this is an upgrade command, check if Homebrew still owns 'node'.
    # If yes, force remove it to prevent conflicts with fnm.
    # if [[ "$1" == "upgrade" || "$1" == "up" ]]; then
    #   if brew list --versions node &> /dev/null; then
    #     echo "⚠️  Detected Homebrew Node.js. Removing to prioritize fnm..."
    #     command brew uninstall --ignore-dependencies --force node
    #     echo "✅ Homebrew Node.js removed."
    #   fi
    # fi

    # Forward ALL commands (install, uninstall, list, etc.) directly to real brew
    command brew "$@"
    local brew_status=$?

    # If the first argument is 'upgrade' (or 'up') and brew succeeded
    if [[ "$1" == "upgrade" || "$1" == "up" ]] && [[ $brew_status -eq 0 ]]; then
      # 1. Capture the ACTIVE version BEFORE installing
      local node_before
      node_before=$(node -v 2>/dev/null || echo "none")

      echo "🚀 Checking Node.js via fnm..."
      fnm install --latest
      fnm default "$(fnm list | grep -o 'v[0-9.]*' | sort -V | tail -n 1 | sed 's/^v//')"
      fnm use default

      # 2. Capture the ACTIVE version AFTER installing
      local node_after
      node_after=$(node -v 2>/dev/null || echo "none")

      # 3. Only proceed if the default alias target changed
      if [[ "$node_before" != "$node_after" ]]; then
        echo "✅ Node updated from $node_before to $node_after"
      fi
    fi
    return $brew_status
  }

  alias brew='_brew_wrapper'
fi

h() {
    # check if we passed any parameters
    if [ -z "$*" ]; then
        # if no parameters were passed print entire history
        history 1
    else
        # if words were passed use it as a search
        history 1 | grep -E --color=auto "$@"
    fi
}
