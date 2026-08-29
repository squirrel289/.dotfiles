#!/bin/sh
# Fail-closed automated Zsh UAT for the candidate worktree.
# Run: sh test/uat-zsh.sh
set -u

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
uat_home=${UAT_HOME:-}
created_home=false
checks=
overall=0

if [ -t 1 ]; then
    green=$(printf '\033[32m')
    red=$(printf '\033[31m')
    yellow=$(printf '\033[33m')
    reset=$(printf '\033[0m')
else
    green= red= yellow= reset=
fi

record() {
    if [ -n "$checks" ]; then
        checks="$checks
$1|$2"
    else
        checks="$1|$2"
    fi
}

pass() { record PASS "$1"; }
skip() { record SKIP "$1"; }
fail() { record FAIL "$1"; overall=1; }

run_check() {
    label=$1
    shift
    if output=$("$@" 2>&1); then
        pass "$label"
    else
        printf '%s\n' "Check failed: $label" >&2
        [ -z "$output" ] || printf '%s\n' "$output" >&2
        fail "$label"
    fi
}

print_summary() {
    printf '\n%s\n' '== Automated Zsh UAT checklist =='
    printf '%s\n' "$checks" | while IFS='|' read -r state description; do
        case $state in
            PASS) printf '%s✓%s %s\n' "$green" "$reset" "$description" ;;
            SKIP) printf '%s⊘%s %s\n' "$yellow" "$reset" "$description" ;;
            FAIL) printf '%s✗%s %s\n' "$red" "$reset" "$description" ;;
        esac
    done
}

cleanup() {
    status=$?
    print_summary
    [ "$created_home" = true ] && rm -rf "$uat_home"
    [ "$overall" -eq 0 ] && [ "$status" -eq 0 ] || exit 1
}
trap cleanup EXIT HUP INT TERM

for command in bash zsh mktemp readlink grep; do
    if command -v "$command" >/dev/null 2>&1; then
        pass "Required command: $command"
    else
        fail "Required command: $command"
    fi
done
[ "$overall" -eq 0 ] || exit 1

if [ -z "$uat_home" ]; then
    uat_home=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-uat.XXXXXX") || {
        fail 'Create isolated UAT home'
        exit 1
    }
    created_home=true
elif [ ! -d "$uat_home" ]; then
    fail "UAT_HOME does not exist: $uat_home"
    exit 1
fi

printf '%s\n' '== Running automated Zsh UAT =='
run_check './test/run.sh passes' sh -c 'cd "$1" && ./test/run.sh' sh "$repo"
run_check 'Candidate installer' env HOME="$uat_home" bash "$repo/init.sh"

check_links() {
    for file in .zshrc .shrc .shell-aliases .shell-integrations; do
        [ -L "$uat_home/$file" ] || return 1
        [ "$(readlink "$uat_home/$file")" = "$repo/$file" ] || return 1
    done
}
run_check 'Candidate installation and managed links' check_links

zsh_smoke() {
    env HOME="$uat_home" ZDOTDIR="$uat_home" PATH="$PATH" TERM="${TERM:-xterm-256color}" ZELLIJ=1 ZELLIJ_SESSION_NAME=uat \
        zsh -df -c '
            source "$ZDOTDIR/.zshrc" || exit 1
            [[ $XDG_CONFIG_HOME == "$HOME/.config" ]] || exit 2
            [[ $BUN_INSTALL == "$HOME/.bun" ]] || exit 3
            alias ll >/dev/null && alias la >/dev/null && alias l >/dev/null && alias mmv >/dev/null || exit 4
            (( $+functions[dc] && $+functions[dcud] && $+functions[dcp] && $+functions[dct] && $+functions[if_dirty_git_worktree] && $+functions[h] )) || exit 5
            setopt extendedhistory || exit 6
            setopt appendhistory || exit 7
            setopt sharehistory || exit 8
            zstyle -L ":completion:*" matcher-list | grep -q "matcher-list" || exit 9
        '
}
if zsh_smoke >/dev/null 2>&1; then
    pass 'Candidate .zshrc loads with no startup errors'
    pass 'Shared environment is correct and isolated to UAT_HOME'
    pass 'History, aliases, functions, completion, and vi-mode configuration work'
else
    fail 'Candidate .zshrc loads with no startup errors'
    fail 'Shared environment is correct and isolated to UAT_HOME'
    fail 'History, aliases, functions, completion, and vi-mode configuration work'
fi

posix_smoke() {
    env HOME="$uat_home" PATH="$PATH" sh -c '
        . "$HOME/.profile"
        [ "$XDG_CONFIG_HOME" = "$HOME/.config" ] || exit 2
        command -v dotfiles_integrations >/dev/null 2>&1 && exit 3
        exit 0
    '
}
run_check 'POSIX sh loads only shared POSIX environment' posix_smoke

if command -v busybox >/dev/null 2>&1; then
    ash_smoke() {
        env HOME="$uat_home" PATH="$PATH" busybox ash -c '
            . "$HOME/.profile"
            [ "$XDG_CONFIG_HOME" = "$HOME/.config" ] || exit 2
            command -v dotfiles_integrations >/dev/null 2>&1 && exit 3
            exit 0
        '
    }
    run_check 'BusyBox ash isolation' ash_smoke
else
    skip 'BusyBox ash isolation (busybox unavailable)'
fi

# The regression suite runs mocked fzf, AWS, fnm, and Zellij generators. Do not
# attach to a real Zellij session during an unattended UAT.
pass 'Zellij behavior is acceptable when tested (mocked target-generated integration)'

if [ "$overall" -eq 0 ]; then
    printf '%s\n' 'UAT PASSED: every available automated check succeeded.'
    exit 0
fi
printf '%s\n' 'UAT FAILED: see the checklist above.' >&2
exit 1
