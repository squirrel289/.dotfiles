#!/usr/bin/env bash
# Authoritative dotfiles install manifest.

managed_files=(
  .gitconfig .gitconfig.macos .gitconfig.windows .shrc .shell-integrations .shell-aliases
  .profile .bash_profile .bashrc .bash_aliases .zshrc .tmux.conf .vimrc .vim
)

managed_config_children=(configstore gtk-2.0 inkscape nvim)

portable_pi_files=(AGENTS.md settings.json models-store.json pi-vcc-config.json)
