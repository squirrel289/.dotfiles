# This script is only executed after login.
# Most actions should be added to .bashrc.

if [[ -z "${BASH_PROFILE_INIT}" ]]; then
  BASH_PROFILE_INIT=set
else
  return 0
fi 

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
<<<<<<< HEAD
=======

HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"
>>>>>>> 90488ea459ab2afa4f28b7dd9c694c76fb1be054
