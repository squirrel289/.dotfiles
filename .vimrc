" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
" Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'junegunn/vim-easy-align'
Plug 'flazz/vim-colorschemes'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-obsession'
Plug 'PProvost/vim-ps1'
Plug 'scrooloose/syntastic'
Plug 'scrooloose/nerdtree'
Plug 'kien/ctrlp.vim'
Plug 'airblade/vim-gitgutter'
Plug 'scrooloose/nerdcommenter'
Plug 'bling/vim-airline'
Plug 'tpope/vim-repeat'
Plug 'pangloss/vim-javascript'
Plug 'ervandew/supertab'
Plug 'easymotion/vim-easymotion'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'terryma/vim-multiple-cursors'
Plug 'shougo/unite.vim'

" Any valid git URL is allowed
" Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
" Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" Plug 'tpope/vim-fireplace', { 'for': 'clojure' }



" Using a non-master branch
" Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
" Plug 'fatih/vim-go', { 'tag': '*' }

" Plugin options
" Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'

" Initialize plugin system
call plug#end()

" EasyAlign mappings
"  Markdown Table mappings
"  'tab' aligns selected markdown table
au FileType markdown vmap <tab> :EasyAlign*<Bar><Enter>\
"  '|' selects and aligns markdown table
au FileType markdown map <Bar> vip :EasyAlign*<Bar><Enter>

set shell=powershell
set shellcmdflag=-command

" Key mappings to move lines
" http://vim.wikia.com/wiki/Moving_lines_up_or_down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Key mappings to enable arrow keys
" https://github.com/krisleech/vimfiles/wiki/Enable-arrow-keys
nnoremap <Left> h                
nnoremap <Right> l                                                              
nnoremap <Up> k                                                                 
nnoremap <Down> j                                                               
inoremap <up> k                                                                 
inoremap <down> j                                                               
inoremap <left> h                                                               
inoremap <right> k

" Key mappings to more easily navigate tabs
nnoremap <A-h> :tabp<Enter>
nnoremap <A-l> :tabn<Enter>

