#!/bin/sh
# Installer regression coverage; uses an isolated HOME and no user files.
set -eu
repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-init.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

home=$tmp/home
mkdir -p "$home"
env HOME="$home" bash "$repo/init.sh" >/dev/null || fail 'clean install failed'
[ -L "$home/.bashrc" ] && [ "$(readlink "$home/.bashrc")" = "$repo/.bashrc" ] || fail 'installer did not link .bashrc'
[ -L "$home/.shell-integrations" ] || fail 'installer did not link dispatcher'
env HOME="$home" bash "$repo/init.sh" >/dev/null || fail 'idempotent install failed'

conflict=$tmp/conflict
mkdir -p "$conflict"
printf '%s\n' original >"$conflict/.bashrc"
if env HOME="$conflict" bash "$repo/init.sh" >/dev/null 2>&1; then
    fail 'installer accepted a conflicting managed target'
fi
[ "$(cat "$conflict/.bashrc")" = original ] || fail 'conflict was overwritten'
env HOME="$conflict" bash "$repo/init.sh" --backup-existing >/dev/null || fail 'backup install failed'
[ -L "$conflict/.bashrc" ] || fail 'backup install did not link replacement'
ls "$conflict/.bashrc.backup-"* >/dev/null 2>&1 || fail 'backup install did not retain conflict'
printf '%s\n' 'init: ok'
