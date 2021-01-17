GITCONFIG=".gitconfig"
BASH_PROFILE=".bash_profile"
PROFILE=".profile"
VIMRC=".vimrc"
VIMDIR=".vim"
CONFIG=".config"

clear_path(){
  FILE="$1"
  if [ -L "$FILE" ]; then
    echo "Link ${FILE} exists"
    rm "${FILE}"
  elif [ -e "$FILE" ]; then
    echo "File ${FILE} exists"
    mv "$FILE" "${FILE}_bk"
  fi
}
clear_path "${HOME}/${GITCONFIG}"
clear_path "${HOME}/${BASH_PROFILE}"
clear_path "${HOME}/${PROFILE}"
clear_path "${HOME}/${VIMRC}"
clear_path "${HOME}/${CONFIG}"
clear_path "${HOME}/${VIMDIR}"

ln -s "${PWD}/${GITCONFIG}" "${HOME}/"
ln -s "${PWD}/${BASH_PROGILE}" "${HOME}/"
ln -s "${PWD}/${PROFILE}" "${HOME}/"
ln -s "${PWD}/${VIMRC}" "${HOME}/"
ln -s "${PWD}/${VIMDIR}" "${HOME}/"
ln -s "${PWD}/${CONFIG}" "${HOME}/"
