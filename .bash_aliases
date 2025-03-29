# enable color support of ls and also add handy aliases
if $USE_COLORS && [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

alias m4b-tool='docker run -it --rm -u $(id -u):$(id -g) -v /mnt/data/downloads/completed/book:/mnt sandreas/m4b-tool:latest'

dc() {
  cur=`pwd`
  cd "$1" && docker-compose ${@:2} || true
  cd "$cur"
}

dcud() {
  dc $1 up -d ${@:2}
}

dcp() {
  dc $1 pull ${@:2}
}

dct() {
  dc $1 logs --tail 100 ${@:2}
}
