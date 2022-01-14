GITCONFIG=".gitconfig"
BASH_PROFILE=".bash_profile"
BASH_ALIASES=".bash_aliases"
BASHRC=".bashrc"
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
clear_path "${HOME}/${BASH_ALIASES}"
clear_path "${HOME}/${BASHRC}"
clear_path "${HOME}/${PROFILE}"
clear_path "${HOME}/${VIMRC}"
clear_path "${HOME}/${CONFIG}"
clear_path "${HOME}/${VIMDIR}"

ln -s "${PWD}/${GITCONFIG}" "${HOME}/"
ln -s "${PWD}/${BASH_PROFILE}" "${HOME}/"
ln -s "${PWD}/${BASH_ALIASES}" "${HOME}/"
ln -s "${PWD}/${BASHRC}" "${HOME}/"
ln -s "${PWD}/${PROFILE}" "${HOME}/"
ln -s "${PWD}/${VIMRC}" "${HOME}/"
ln -s "${PWD}/${VIMDIR}" "${HOME}/"
ln -s "${PWD}/${CONFIG}" "${HOME}/"

curl -fLo "{$HOME}/{$VIMDIR}/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
