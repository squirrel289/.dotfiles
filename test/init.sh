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
[ -d "$home/.pi" ] && [ ! -L "$home/.pi" ] || fail 'installer replaced the Pi state directory'
[ -L "$home/.pi/agent/settings.json" ] && [ "$(readlink "$home/.pi/agent/settings.json")" = "$repo/pi-config/agent/settings.json" ] || fail 'installer did not link portable Pi settings'
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

dry_run_home=$tmp/dry-run
mkdir -p "$dry_run_home"
dry_run_output=$(env HOME="$dry_run_home" bash "$repo/init.sh" --dry-run)
printf '%s\n' "$dry_run_output" | grep 'change:' >/dev/null || fail 'dry-run did not report planned changes'
[ ! -e "$dry_run_home/.bashrc" ] || fail 'dry-run created a managed link'
[ ! -e "$dry_run_home/.config" ] || fail 'dry-run created .config'

force_home=$tmp/force
mkdir -p "$force_home"
printf '%s\n' original >"$force_home/.bashrc"
env HOME="$force_home" bash "$repo/init.sh" --force >/dev/null || fail 'force install failed'
[ -L "$force_home/.bashrc" ] || fail 'force install did not link replacement'
if ls "$force_home/.bashrc.backup-"* >/dev/null 2>&1; then
    fail 'force install unexpectedly retained a backup'
fi

# A managed file must never replace or relocate an existing directory, even
# when conflict backups are requested.  .pi is intentionally unmanaged.
directory_conflict=$tmp/directory-conflict
mkdir -p "$directory_conflict/.profile" "$directory_conflict/.pi"
printf '%s\n' profile-data >"$directory_conflict/.profile/keep"
printf '%s\n' pi-data >"$directory_conflict/.pi/keep"
if env HOME="$directory_conflict" bash "$repo/init.sh" --backup-existing >/dev/null 2>&1; then
    fail 'backup install accepted a directory where a managed file belongs'
fi
[ -d "$directory_conflict/.profile" ] && [ ! -L "$directory_conflict/.profile" ] || fail 'installer replaced .profile directory'
[ "$(cat "$directory_conflict/.profile/keep")" = profile-data ] || fail 'installer relocated .profile directory'
[ -d "$directory_conflict/.pi" ] && [ ! -L "$directory_conflict/.pi" ] || fail 'installer linked unmanaged .pi directory'

# Pi's state directory is retained; only explicitly portable files may be linked.
pi_home=$tmp/pi-home
mkdir -p "$pi_home/.pi/agent"
printf '%s\n' local-state >"$pi_home/.pi/keep"
printf '%s\n' local-settings >"$pi_home/.pi/agent/settings.json"
if env HOME="$pi_home" bash "$repo/init.sh" >/dev/null 2>&1; then
    fail 'installer accepted conflicting portable Pi settings'
fi
[ "$(cat "$pi_home/.pi/agent/settings.json")" = local-settings ] || fail 'installer overwrote local Pi settings'
env HOME="$pi_home" bash "$repo/init.sh" --backup-existing >/dev/null || fail 'Pi settings backup install failed'
[ -d "$pi_home/.pi" ] && [ ! -L "$pi_home/.pi" ] || fail 'installer replaced the Pi state directory'
[ "$(cat "$pi_home/.pi/keep")" = local-state ] || fail 'installer relocated Pi state'
[ -L "$pi_home/.pi/agent/settings.json" ] && [ "$(readlink "$pi_home/.pi/agent/settings.json")" = "$repo/pi-config/agent/settings.json" ] || fail 'installer did not link portable Pi settings after backup'
ls "$pi_home/.pi/agent/settings.json.backup-"* >/dev/null 2>&1 || fail 'installer did not retain local Pi settings'
printf '%s\n' 'init: ok'
