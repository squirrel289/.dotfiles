#!/usr/bin/env bash
# Bash-only dotfiles installer. It links only the manifest and never downloads plugins.
set -euo pipefail

backup_existing=false
dry_run=false
force=false
verbose=false

usage() {
  printf '%s\n' 'Usage: init.sh [--dry-run] [--verbose] [--backup-existing | --force]'
  printf '%s\n' 'Links managed files into $HOME.'
  printf '%s\n' '  --dry-run          Show planned changes without modifying files.'
  printf '%s\n' '  --verbose          Also show already-correct targets.'
  printf '%s\n' '  --backup-existing  Move conflicting managed targets aside first.'
  printf '%s\n' '  --force            Replace conflicting non-directory targets without backup.'
}

while [ $# -gt 0 ]; do
  case $1 in
    --backup-existing) backup_existing=true ;;
    --dry-run) dry_run=true ;;
    --force) force=true ;;
    --verbose) verbose=true ;;
    --help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

if "$backup_existing" && "$force"; then
  printf '%s\n' 'error: choose only one of --backup-existing or --force' >&2
  exit 2
fi

script_dir=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/manifest.sh"

log_action() {
  local status=$1 path=$2 detail=${3:-}
  if [ "$status" = ok ] && ! "$verbose"; then
    return 0
  fi
  if [ -n "$detail" ]; then
    printf '%s: %s -> %s\n' "$status" "$path" "$detail"
  else
    printf '%s: %s\n' "$status" "$path"
  fi
}

backup_path() {
  local destination=$1 stamp candidate number
  stamp=$(date +%Y%m%d%H%M%S)
  candidate="${destination}.backup-${stamp}"
  number=1
  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    candidate="${destination}.backup-${stamp}-${number}"
    number=$((number + 1))
  done
  printf '%s\n' "$candidate"
}

link_managed() {
  local source=$1 destination=$2 backup
  # Managed startup entries are files except .vim.  Never "back up" a
  # directory to make room for one: it may be application state (for example,
  # a pre-existing .profile directory) and moving it is destructive.
  if [ -d "$destination" ] && [ ! -d "$source" ]; then
    log_action error "$destination" 'directory exists where managed file belongs' >&2
    return 1
  fi
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    log_action ok "$destination" "$source"
    return 0
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if ! "$backup_existing" && ! "$force"; then
      log_action error "$destination" 'conflicting target exists; use --backup-existing or --force' >&2
      return 1
    fi
    if "$backup_existing"; then
      backup=$(backup_path "$destination")
      if "$dry_run"; then
        log_action change "$destination" "would back up to $backup"
      else
        mv "$destination" "$backup"
        log_action change "$destination" "backed up to $backup"
      fi
    elif [ -d "$destination" ]; then
      log_action error "$destination" 'refusing to force-remove directory; use --backup-existing' >&2
      return 1
    elif "$dry_run"; then
      log_action change "$destination" 'would remove conflicting target'
    else
      rm "$destination"
      log_action change "$destination" 'removed conflicting target'
    fi
  fi
  if "$dry_run"; then
    log_action change "$destination" "would link $source"
  else
    ln -s "$source" "$destination"
    log_action change "$destination" "$source"
  fi
}

config_destination=$HOME/.config
if [ -L "$config_destination" ]; then
  if [ "$(readlink "$config_destination")" = "$script_dir/.config" ]; then
    if "$dry_run"; then
      log_action change "$config_destination" 'would replace legacy symlink with directory'
    else
      rm "$config_destination"
      mkdir -p "$config_destination"
      log_action change "$config_destination" 'replaced legacy symlink with directory'
    fi
  else
    log_action error "$config_destination" 'unknown symlink target' >&2
    exit 1
  fi
elif [ ! -e "$config_destination" ]; then
  if "$dry_run"; then
    log_action change "$config_destination" 'would create directory'
  else
    mkdir -p "$config_destination"
    log_action change "$config_destination" 'created directory'
  fi
elif [ ! -d "$config_destination" ]; then
  log_action error "$config_destination" 'non-directory target exists' >&2
  exit 1
else
  log_action ok "$config_destination" 'directory exists'
fi

for target in "${managed_files[@]}"; do
  link_managed "$script_dir/$target" "$HOME/$target"
done

for target in "${managed_config_children[@]}"; do
  link_managed "$script_dir/.config/$target" "$config_destination/$target"
done

# Pi keeps credentials, sessions, caches, and installed packages in ~/.pi.
# Only the reviewed files in pi-config are portable; never replace the state
# directory with the historical ~/.dotfiles/.pi symlink.
pi_destination=$HOME/.pi
if [ -L "$pi_destination" ]; then
  log_action error "$pi_destination" 'refusing Pi state-directory symlink' >&2
  exit 1
elif [ -e "$pi_destination" ] && [ ! -d "$pi_destination" ]; then
  log_action error "$pi_destination" 'non-directory Pi state target exists' >&2
  exit 1
elif [ ! -e "$pi_destination" ]; then
  if "$dry_run"; then
    log_action change "$pi_destination" 'would create directory'
  else
    mkdir -p "$pi_destination"
    log_action change "$pi_destination" 'created directory'
  fi
else
  log_action ok "$pi_destination" 'directory exists'
fi
if "$dry_run"; then
  if [ ! -d "$pi_destination/agent" ]; then
    log_action change "$pi_destination/agent" 'would create directory'
  else
    log_action ok "$pi_destination/agent" 'directory exists'
  fi
else
  mkdir -p "$pi_destination/agent"
  log_action ok "$pi_destination/agent" 'directory exists'
fi
for target in "${portable_pi_files[@]}"; do
  link_managed "$script_dir/pi-config/agent/$target" "$pi_destination/agent/$target"
done
