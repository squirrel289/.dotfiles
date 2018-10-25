if [ ! -f ~/.bashrc ]; then
  echo "export HISTCONTROL=ignoreboth:erasedups" > .bashrc
  chmod u+x ~/.bashrc
fi
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi