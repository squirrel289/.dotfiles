if [ -d ~/nvim-osx64/bin ]; then
  export PATH="${PATH}:~/nvim-osx64/bin"
fi

if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
  set XDG_CONFIG_HOME = "$HOME/.config"
  if [ ! -d $XDG_CONFIG_HOME ]; then
    mkdir -p $XDG_CONFIG_HOME
    ln -s ~/.vim $XDG_CONFIG_HOME/nvim
    ln -s ~/.vimrc $XDG_CONFIG_HOME/nvim/init.vim
  fi
fi

if type vim > /dev/null 2>&1; then
  alias vi='vim'
fi

aws_completer_path=`which aws_completer`

if [ -f $aws_completer_path ]; then
  complete -C '$aws_completer_path' aws
fi

if [ ! -f ~/.bashrc ]; then
  echo "export HISTCONTROL=ignoreboth:erasedups" > .bashrc
  chmod u+x ~/.bashrc
fi

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

alias la='ls -la'
alias ll='ls -l'
