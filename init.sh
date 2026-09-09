#!/usr/bin/env bash
# Bash-only dotfiles installer. It links only the manifest below and never downloads plugins.
set -euo pipefail

backup_existing=false
case ${1:-} in
  '') ;;
  --backup-existing) backup_existing=true ;;
  --help)
    printf '%s\n' 'Usage: init.sh [--backup-existing]'
    printf '%s\n' 'Links managed files into $HOME; --backup-existing moves conflicting managed targets aside.'
    exit 0
    ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

script_dir=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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
    printf 'Refusing directory where managed file belongs: %s\n' "$destination" >&2
    return 1
  fi
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    return 0
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if ! "$backup_existing"; then
      printf 'Refusing conflicting target: %s\n' "$destination" >&2
      return 1
    fi
    backup=$(backup_path "$destination")
    mv "$destination" "$backup"
    printf 'Backed up %s to %s\n' "$destination" "$backup"
  fi
  ln -s "$source" "$destination"
}

config_destination=$HOME/.config
if [ -L "$config_destination" ]; then
  if [ "$(readlink "$config_destination")" = "$script_dir/.config" ]; then
    rm "$config_destination"
    mkdir -p "$config_destination"
  else
    printf 'Refusing unknown .config symlink: %s\n' "$config_destination" >&2
    exit 1
  fi
elif [ ! -e "$config_destination" ]; then
  mkdir -p "$config_destination"
elif [ ! -d "$config_destination" ]; then
  printf 'Refusing non-directory .config target: %s\n' "$config_destination" >&2
  exit 1
fi

managed_files=(
  .gitconfig .gitconfig.macos .gitconfig.windows .shrc .shell-integrations .shell-aliases
  .profile .bash_profile .bashrc .bash_aliases .zshrc .tmux.conf .vimrc .vim
)
for target in "${managed_files[@]}"; do
  link_managed "$script_dir/$target" "$HOME/$target"
done

managed_config_children=(configstore gtk-2.0 inkscape nvim zellij)
for target in "${managed_config_children[@]}"; do
  link_managed "$script_dir/.config/$target" "$config_destination/$target"
done

# Pi keeps credentials, sessions, caches, and installed packages in ~/.pi.
# Only the reviewed files in pi-config are portable; never replace the state
# directory with the historical ~/.dotfiles/.pi symlink.
pi_destination=$HOME/.pi
if [ -L "$pi_destination" ]; then
  printf 'Refusing Pi state-directory symlink: %s\n' "$pi_destination" >&2
  exit 1
elif [ -e "$pi_destination" ] && [ ! -d "$pi_destination" ]; then
  printf 'Refusing non-directory Pi state target: %s\n' "$pi_destination" >&2
  exit 1
elif [ ! -e "$pi_destination" ]; then
  mkdir -p "$pi_destination"
fi
mkdir -p "$pi_destination/agent"
portable_pi_files=(AGENTS.md settings.json models-store.json pi-vcc-config.json)
for target in "${portable_pi_files[@]}"; do
  link_managed "$script_dir/pi-config/agent/$target" "$pi_destination/agent/$target"
done
