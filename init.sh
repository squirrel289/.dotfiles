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

managed_config_children=(configstore gtk-2.0 inkscape nvim)
for target in "${managed_config_children[@]}"; do
  link_managed "$script_dir/.config/$target" "$config_destination/$target"
done
