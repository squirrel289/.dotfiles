# POSIX login entrypoint. Bash and Zsh use their native entrypoints instead.
[ -r "$HOME/.shrc" ] && . "$HOME/.shrc"
