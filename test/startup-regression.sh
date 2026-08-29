#!/bin/sh
# Startup policy regression coverage. Run through test/run.sh from the repository root.
# The harness uses only POSIX sh plus Bash; Zsh and BusyBox ash are optional.
set -eu
repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-startup.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
home=$tmp/home
mock=$tmp/mock
log=$tmp/log
clean_path=$mock:/usr/bin:/bin
mkdir -p "$home" "$mock"
: >"$log"

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
make_tool() { cat >"$mock/$1"; chmod +x "$mock/$1"; }
link_startup() {
    target=$1
    mkdir -p "$target"
    for file in .profile .shrc .bash_profile .bashrc .bash_aliases .shell-aliases .shell-integrations .zshrc; do
        ln -s "$repo/$file" "$target/$file"
    done
}
run_bash_interactive() {
    command=$1
    baseline=$(env HOME="$home" PATH="$clean_path" TERM=dumb bash --noprofile --norc -ic ':' 2>&1) || fail 'interactive Bash baseline failed'
    output=$(env HOME="$home" PATH="$clean_path" TERM=dumb bash --noprofile --norc -ic "$command" 2>&1) || fail "interactive Bash assertion failed: $output"
    [ "$output" = "$baseline" ] || fail "interactive Bash wrote unexpected output: $output"
}

link_startup "$home"

# Noninteractive Bash must return before every interactive policy or integration.
for tool in tmux zellij fzf aws_completer; do
    make_tool "$tool" <<EOF
a#!/bin/sh
printf '%s\n' '$tool' >>"$log"
EOF
    sed -i.bak '1s/^a//' "$mock/$tool" && rm -f "$mock/$tool.bak"
done
# vim/nvim capability discovery must not run either; these scripts log only if executed.
make_tool vim <<EOF
#!/bin/sh
printf '%s\n' vim >>"$log"
EOF
make_tool nvim <<EOF
#!/bin/sh
printf '%s\n' nvim >>"$log"
EOF
: >"$log"
env HOME="$home" PATH="$clean_path" bash --noprofile --norc -c '. "$HOME/.bashrc"; test -z "${HISTCONTROL:-}"; ! alias ll >/dev/null 2>&1; ! declare -F dc >/dev/null 2>&1; test -z "${PS1:-}"' || fail 'noninteractive Bash loaded interactive policy'
[ ! -s "$log" ] || fail 'noninteractive Bash executed a mocked tool'
env HOME="$home" PATH="$clean_path" bash --noprofile --norc -c '. "$HOME/.bash_profile"; test "$XDG_CONFIG_HOME" = "$HOME/.config"; test "$BUN_INSTALL" = "$HOME/.bun"; test -z "${HISTCONTROL:-}"; ! alias ll >/dev/null 2>&1' || fail 'noninteractive login boundary changed'

# Prompt, history, and re-sourcing behavior are exact and host completion is isolated by POSIX mode.
run_bash_interactive 'set -o posix; debian_chroot=test; PROMPT_COMMAND=prior; unset force_color_prompt; . "$HOME/.bashrc"; test "$HISTCONTROL" = ignoreboth:erasedups; test "$HISTSIZE" = 1000; test "$HISTFILESIZE" = 2000; shopt -q histappend; shopt -q checkwinsize; test "$PROMPT_COMMAND" = "history -n; history -w;history -c;history -r;prior"; test "$PS1" = "${debian_chroot:+($debian_chroot)}\\u@\\h:\\w\\$ "; . "$HOME/.bashrc"; test "$PROMPT_COMMAND" = "history -n; history -w;history -c;history -r;prior"'
baseline=$(env HOME="$home" PATH="$clean_path" TERM=xterm-256color bash --noprofile --norc -ic ':' 2>&1) || fail 'xterm Bash baseline failed'
output=$(env HOME="$home" PATH="$clean_path" TERM=xterm-256color bash --noprofile --norc -ic 'set -o posix; debian_chroot=test; PROMPT_COMMAND=prior; . "$HOME/.bashrc"; case "$PS1" in *"\\[\\e]0;"*"\\[\\033[01;32m\\]"*"\\[\\033[01;34m\\]"*) ;; *) exit 1 ;; esac' 2>&1) || fail 'color prompt assertion failed'
[ "$output" = "$baseline" ] || fail 'color prompt wrote unexpected output'

# force_color_prompt uses tput when it can set a color and falls back to a plain prompt otherwise.
TERM=xterm /usr/bin/tput setaf 1 >/dev/null 2>&1 || fail 'test host cannot exercise forced-color success path'
baseline=$(env HOME="$home" PATH="$clean_path" TERM=xterm bash --noprofile --norc -ic ':' 2>&1) || fail 'forced-color Bash baseline failed'
output=$(env HOME="$home" PATH="$clean_path" TERM=xterm bash --noprofile --norc -ic 'set -o posix; force_color_prompt=1; . "$HOME/.bashrc"; case "$PS1" in *"\[\033[01;32m\]"*) ;; *) exit 1 ;; esac' 2>&1) || fail 'forced-color success assertion failed'
[ "$output" = "$baseline" ] || fail 'forced-color success wrote unexpected output'
expected_plain_prompt='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
export expected_plain_prompt
run_bash_interactive 'set -o posix; force_color_prompt=1; . "$HOME/.bashrc"; test "$PS1" = "$expected_plain_prompt"'

# Mock each host bash-completion location without reading host completion scripts.
completion_primary=$tmp/bash_completion_primary
completion_fallback=$tmp/bash_completion_fallback
completion_bashrc=$tmp/bashrc-completion
completion_log=$tmp/completion.log
printf '%s\n' 'printf primary >>"$COMPLETION_LOG"' >"$completion_primary"
printf '%s\n' 'printf fallback >>"$COMPLETION_LOG"' >"$completion_fallback"
sed "s|/usr/share/bash-completion/bash_completion|$completion_primary|; s|/etc/bash_completion|$completion_fallback|" "$repo/.bashrc" >"$completion_bashrc"
: >"$completion_log"
baseline=$(env HOME="$home" PATH="$clean_path" TERM=dumb bash --noprofile --norc -ic ':' 2>&1) || fail 'completion Bash baseline failed'
output=$(env HOME="$home" PATH="$clean_path" TERM=dumb COMPLETION_LOG="$completion_log" BASHRC="$completion_bashrc" bash --noprofile --norc -ic '. "$BASHRC"' 2>&1) || fail 'primary completion assertion failed'
[ "$output" = "$baseline" ] || fail 'primary completion wrote unexpected output'
[ "$(cat "$completion_log")" = primary ] || fail 'primary bash-completion path was not preferred'
rm "$completion_primary"
: >"$completion_log"
output=$(env HOME="$home" PATH="$clean_path" TERM=dumb COMPLETION_LOG="$completion_log" BASHRC="$completion_bashrc" bash --noprofile --norc -ic '. "$BASHRC"' 2>&1) || fail 'fallback completion assertion failed'
[ "$output" = "$baseline" ] || fail 'fallback completion wrote unexpected output'
[ "$(cat "$completion_log")" = fallback ] || fail 'fallback bash-completion path was not used'

# Aliases, helper functions, color aliases, editor choice, and dc directory restoration.
make_tool ls <<'EOF'
#!/bin/sh
exit 0
EOF
make_tool dircolors <<'EOF'
#!/bin/sh
printf '%s\n' 'LS_COLORS=di=01; export LS_COLORS'
EOF
for tool in podman code pi brew fnm; do
    make_tool "$tool" <<EOF
#!/bin/sh
exit 0
EOF
done
make_tool docker-compose <<EOF
#!/bin/sh
printf '%s:%s\n' "\$PWD" "\$*" >>"$log"
EOF
work=$tmp/work
origin=$tmp/origin
mkdir -p "$work" "$origin"
work=$(CDPATH= cd "$work" && pwd)
origin=$(CDPATH= cd "$origin" && pwd)
export work origin
rm -f "$mock/tmux" "$mock/zellij" "$mock/fzf" "$mock/aws_completer"
: >"$log"
run_bash_interactive 'set -o posix; . "$HOME/.bashrc"; alias ll="ls -la"; alias la="ls -A"; alias l="ls -CF"; alias s=ssh; alias g=git; alias get_id="openssl rand -hex "; alias m4b-tool >/dev/null; alias docker=podman; alias vs=code; alias commit >/dev/null; alias vim=nvim; alias vi=vim; alias ls="ls --color=auto"; alias brew=_brew_wrapper; declare -F dc >/dev/null; declare -F dcud >/dev/null; declare -F dcp >/dev/null; declare -F dct >/dev/null; declare -F if_dirty_git_worktree >/dev/null; declare -F _brew_wrapper >/dev/null; cd "$origin"; dc "$work" testarg; test "$PWD" = "$origin"; dcud "$work" service; dcp "$work" service; dct "$work" service; test "$PWD" = "$origin"'
printf '%s\n' "$work:testarg" "$work:up -d service" "$work:pull service" "$work:logs --tail 100 service" >"$tmp/expected-dc-log"
cmp -s "$tmp/expected-dc-log" "$log" || fail 'dc helpers did not run in the requested directory or restore PWD'

# Companion commands suppress only their matching convenience aliases.
for tool in docker vs commit; do
    make_tool "$tool" <<'EOF'
#!/bin/sh
exit 0
EOF
done
env HOME="$home" PATH="$clean_path" bash --noprofile --norc -c '. "$HOME/.shell-aliases"; ! alias docker >/dev/null 2>&1; ! alias vs >/dev/null 2>&1; ! alias commit >/dev/null 2>&1' || fail 'shared alias companion guard changed'
rm "$mock/docker" "$mock/vs" "$mock/commit"

# The brew wrapper preserves brew status and only updates fnm after a successful upgrade alias.
brew_log=$tmp/brew.log
node_version=$tmp/node-version
make_tool brew <<'EOF'
#!/bin/sh
printf 'brew:%s\n' "$*" >>"$BREW_LOG"
exit "${BREW_STATUS:-0}"
EOF
make_tool fnm <<'EOF'
#!/bin/sh
printf 'fnm:%s\n' "$*" >>"$BREW_LOG"
case $1 in
  install) printf '%s\n' v22.0.0 >"$NODE_VERSION" ;;
  list) printf '%s\n' v20.0.0 v22.0.0 ;;
esac
EOF
make_tool node <<'EOF'
#!/bin/sh
cat "$NODE_VERSION"
EOF
make_tool sort <<'EOF'
#!/bin/sh
cat
EOF
: >"$brew_log"
env HOME="$home" PATH="$clean_path" BREW_LOG="$brew_log" NODE_VERSION="$node_version" bash --noprofile --norc -c '. "$HOME/.bash_aliases"; _brew_wrapper install ripgrep' || fail 'brew wrapper changed successful non-upgrade status'
[ "$(cat "$brew_log")" = 'brew:install ripgrep' ] || fail 'non-upgrade brew invoked fnm'
: >"$brew_log"
if env HOME="$home" PATH="$clean_path" BREW_LOG="$brew_log" NODE_VERSION="$node_version" BREW_STATUS=7 bash --noprofile --norc -c '. "$HOME/.bash_aliases"; _brew_wrapper upgrade'; then
    fail 'failed brew upgrade returned success'
else
    [ "$?" -eq 7 ] || fail 'failed brew upgrade changed its status'
fi
[ "$(cat "$brew_log")" = 'brew:upgrade' ] || fail 'failed brew upgrade invoked fnm'
printf '%s\n' v20.0.0 >"$node_version"
: >"$brew_log"
output=$(env HOME="$home" PATH="$clean_path" BREW_LOG="$brew_log" NODE_VERSION="$node_version" bash --noprofile --norc -c '. "$HOME/.bash_aliases"; _brew_wrapper up' 2>&1) || fail 'successful brew upgrade failed'
expected_brew_output='🚀 Checking Node.js via fnm...
✅ Node updated from v20.0.0 to v22.0.0'
[ "$output" = "$expected_brew_output" ] || fail 'successful brew upgrade output changed'
printf '%s\n' 'brew:up' 'fnm:install --latest' 'fnm:list' 'fnm:default 22.0.0' 'fnm:use default' >"$tmp/expected-brew-log"
cmp -s "$tmp/expected-brew-log" "$brew_log" || fail 'successful brew upgrade fnm behavior changed'

make_tool git <<'EOF'
#!/bin/sh
case $1 in
  rev-parse) case ${GIT_STATE:-} in clean|dirty) printf true ;; *) exit 1 ;; esac ;;
  status) [ "${GIT_STATE:-}" = dirty ] && printf M ;;
esac
EOF
refusal=$tmp/refusal
export refusal
run_bash_interactive 'set -o posix; . "$HOME/.bashrc"; export GIT_STATE=clean; if_dirty_git_worktree true 2>"$refusal"; test "$(cat "$refusal")" = "Repository is clean. Nothing to do..."; GIT_STATE=dirty; if_dirty_git_worktree sh -c "exit 0"; GIT_STATE=outside; if_dirty_git_worktree true 2>"$refusal"; test "$(cat "$refusal")" = "Not in a Git repository. Aborting..."'

# tmux is attempted before generated Zellij startup; markers gate their respective managers.
make_tool tmux <<EOF
#!/bin/sh
printf 'tmux:%s\n' "\$*" >>"$log"
[ "\$1" = attach ] && exit 1
EOF
make_tool zellij <<EOF
#!/bin/sh
printf 'zellij:%s\n' "\$*" >>"$log"
printf '%s\n' 'DOTFILES_ZELLIJ=started'
EOF
: >"$log"
run_bash_interactive 'set -o posix; unset TMUX ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.bashrc"; test "$DOTFILES_ZELLIJ" = started'
printf '%s\n' 'tmux:attach -t default' 'tmux:new -s default' 'zellij:setup --generate-auto-start bash' >"$tmp/expected-log"
cmp -s "$tmp/expected-log" "$log" || fail 'tmux/Zellij ordering changed'
: >"$log"
run_bash_interactive 'set -o posix; TMUX=inside; unset ZELLIJ ZELLIJ_SESSION_NAME; . "$HOME/.bashrc"; test "$DOTFILES_ZELLIJ" = started'
grep -qx 'zellij:setup --generate-auto-start bash' "$log" || fail 'TMUX did not suppress only tmux'
! grep -q '^tmux:' "$log" || fail 'tmux ran inside tmux'
: >"$log"
run_bash_interactive 'set -o posix; TMUX=inside ZELLIJ=inside ZELLIJ_SESSION_NAME=name; . "$HOME/.bashrc"; test -z "${DOTFILES_ZELLIJ:-}"'
[ ! -s "$log" ] || fail 'session markers did not suppress session managers'

# POSIX profile is an isolation boundary, while shared PATH additions are idempotent.
make_tool uname <<'EOF'
#!/bin/sh
printf '%s\n' Linux
EOF
mkdir -p "$home/bin" "$home/.local/bin" "$home/.bun/bin" "$home/.local/share/pnpm" "$home/.local/share/pnpm/bin"
expected_path="$home/go/bin:$home/.local/share/pnpm:$home/.local/share/pnpm/bin:$home/.bun/bin:$home/.local/bin:$home/bin:$clean_path"
env HOME="$home" PATH="$clean_path" XDG_DATA_HOME="$home/.local/share" EXPECTED_PATH="$expected_path" sh -c '. "$HOME/.profile"; test "$PATH" = "$EXPECTED_PATH"; . "$HOME/.profile"; test "$PATH" = "$EXPECTED_PATH"; test "$XDG_CONFIG_HOME" = "$HOME/.config"; test "$PNPM_HOME" = "$XDG_DATA_HOME/pnpm"; ! alias ll >/dev/null 2>&1; ! command -v dotfiles_integrations >/dev/null 2>&1' || fail 'POSIX profile isolation, user-bin ordering, or PATH de-duplication changed'
if command -v busybox >/dev/null 2>&1; then
    env HOME="$home" PATH="$clean_path" busybox ash -c '. "$HOME/.profile"; test "$XDG_CONFIG_HOME" = "$HOME/.config"; ! alias ll >/dev/null 2>&1; ! command -v dotfiles_integrations >/dev/null 2>&1' || fail 'BusyBox ash profile isolation changed'
    printf '%s\n' 'startup-regression: busybox ash ok'
else
    printf '%s\n' 'startup-regression: busybox ash skipped (busybox not installed)'
fi

# Zsh-only policy is deliberately optional on hosts without Zsh.
if command -v zsh >/dev/null 2>&1; then
    zhome=$tmp/zhome
    zmock=$tmp/zmock
    zlog=$tmp/zlog
    mkdir -p "$zhome/.zsh/completion" "$zhome/.dotfiles" "$zmock" "$tmp/brew/share/zsh-autosuggestions" "$tmp/brew/opt/zsh-vi-mode/share/zsh-vi-mode"
    : >"$zlog"
    link_startup "$zhome"
    cat >"$zhome/.dotfiles/history.sh" <<EOF
printf '%s\\n' history >>"$zlog"
EOF
    cat >"$tmp/brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" <<EOF
printf '%s\\n' autosuggestions >>"$zlog"
EOF
    cat >"$tmp/brew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" <<EOF
printf '%s\\n' vi-mode >>"$zlog"
EOF
    mkdir -p "$zhome/.bun"
    cat >"$zhome/.bun/_bun" <<EOF
printf '%s\\n' bun >>"$zlog"
EOF
    cat >"$zhome/.zsh/completion/path-prefix-completion.zsh" <<EOF
printf '%s\\n' path-prefix >>"$zlog"
EOF
    for tool in podman code pi; do
        cat >"$zmock/$tool" <<'EOF'
#!/bin/sh
exit 0
EOF
        chmod +x "$zmock/$tool"
    done
    cat >"$zmock/brew" <<EOF
#!/bin/sh
[ "\$1" = --prefix ] && printf '%s\\n' "$tmp/brew"
EOF
    cat >"$zmock/fnm" <<EOF
#!/bin/sh
printf 'fnm:%s\\n' "\$*" >>"$zlog"
printf '%s\\n' 'DOTFILES_FNM=enabled'
EOF
    cat >"$zmock/zellij" <<EOF
#!/bin/sh
printf 'zellij:%s\\n' "\$*" >>"$zlog"
printf '%s\\n' 'DOTFILES_ZELLIJ=enabled'
EOF
    chmod +x "$zmock/brew" "$zmock/fnm" "$zmock/zellij"
    env HOME="$zhome" PATH="$zmock:/usr/bin:/bin" XDG_RUNTIME_DIR="$tmp/runtime" ZELLIJ= ZELLIJ_SESSION_NAME= LS_COLORS='di=01:fi=00' zsh -df -c '
        . "$HOME/.zshrc"
        test "$RPROMPT" = ""
        test "$fpath[1]" = "$HOME/.zsh/completion"
        alias mmv="noglob zmv -W"; alias ll="ls -la"; alias docker=podman; alias vs=code; alias commit >/dev/null
        whence -w compdef | grep -q "compdef:"
        zstyle -L ":completion:*" list-colors | grep -q "di=01"
        zstyle -L ":completion:*:(scp|rsync):*" tag-order >/dev/null
        zstyle -L ":completion:*:(ssh|scp|rsync):*:hosts-host" ignored-patterns >/dev/null
        zstyle -L ":completion:*:(ssh|scp|rsync):*:hosts-ipaddr" ignored-patterns >/dev/null
        zstyle -L ":completion:*" matcher-list >/dev/null
        for option in extendedhistory incappendhistory sharehistory appendhistory histexpiredupsfirst histignoredups histignorealldups histfindnodups histignorespace histsavenodups histverify; do [[ -o "$option" ]] || exit 1; done
        test "$HISTSIZE" = 1000; test "$SAVEHIST" = 2000; test "$HISTFILESIZE" = 2000; test "$HISTFILE" = "$HOME/.zsh_history"; test "$DOTFILES_FNM" = enabled; test "$DOTFILES_ZELLIJ" = enabled
    ' >/dev/null 2>&1 || fail 'Zsh startup policy assertion failed'
    printf '%s\n' history autosuggestions vi-mode bun 'fnm:env --use-on-cd --version-file-strategy=recursive --shell zsh' path-prefix 'zellij:setup --generate-auto-start zsh' >"$tmp/expected-zlog"
    cmp -s "$tmp/expected-zlog" "$zlog" || fail 'Zsh plugin/generator ordering changed'
    env HOME="$zhome" PATH="$zmock:/usr/bin:/bin" XDG_RUNTIME_DIR="$tmp/runtime" ZELLIJ_SESSION_NAME=session zsh -df -c '. "$HOME/.zshrc"; test "$HISTFILE" = "$HOME/.zsh_history_session"; test -z "${DOTFILES_ZELLIJ:-}"' >/dev/null 2>&1 || fail 'Zsh session-name history/Zellij gate changed'
    env HOME="$zhome" PATH="$zmock:/usr/bin:/bin" XDG_RUNTIME_DIR="$tmp/runtime" ZELLIJ=inside ZELLIJ_SESSION_NAME= zsh -df -c '. "$HOME/.zshrc"; test "$HISTFILE" = "$HOME/.zsh_history"; test -z "${DOTFILES_ZELLIJ:-}"' >/dev/null 2>&1 || fail 'Zsh ZELLIJ marker history/Zellij gate changed'
    printf '%s\n' 'startup-regression: zsh ok'
else
    printf '%s\n' 'startup-regression: zsh skipped (zsh not installed)'
fi
printf '%s\n' 'startup-regression: ok'
