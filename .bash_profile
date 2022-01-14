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
