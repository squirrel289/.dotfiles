# Bash login bridge. Load the shared POSIX environment before interactive policy.
[ -r "$HOME/.profile" ] && . "$HOME/.profile"
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
