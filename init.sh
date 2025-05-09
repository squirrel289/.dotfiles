GITCONFIG=".gitconfig"
BASH_PROFILE=".bash_profile"
BASH_ALIASES=".bash_aliases"
BASHRC=".bashrc"
ZSHRC=".zshrc"
PROFILE=".profile"
VIMRC=".vimrc"
VIMDIR=".vim"
CONFIG=".config"

clear_path(){
  FILE="$1"
  if [ -L "$FILE" ]; then
    echo "Link ${FILE} exists. Recreating..."
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
clear_path "${HOME}/${ZSHRC}"
clear_path "${HOME}/${VIMRC}"
clear_path "${HOME}/${CONFIG}"
clear_path "${HOME}/${VIMDIR}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ln -s "${SCRIPT_DIR}/${GITCONFIG}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${BASH_PROFILE}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${BASH_ALIASES}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${BASHRC}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${PROFILE}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${ZSHRC}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${VIMRC}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${VIMDIR}" "${HOME}/"
ln -s "${SCRIPT_DIR}/${CONFIG}" "${HOME}/"

curl -fLo "$HOME/$VIMDIR/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
