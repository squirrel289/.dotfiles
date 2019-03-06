" filetype plugin indent on
filetype on

function! Gist(name)
    return { 'as': a:name, 'do': 'mkdir -p plugin: cp -f *.vim plugin/' }
endfunction         
                          
" Auto update plug.vim before we use it
if has('win32')
  let vimfiles = '~/vimfiles/plugged' 
  if empty(glob('~/vimfiles/autoload/plug.vim'))              
    silent! md ~\vimfiles\autoload; (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim', $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("~\vimfiles\autoload\plug.vim"));
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif
endif

if has('unix') || has('macunix')
  let vimfiles = '~/.vim/plugged' 
  if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(vimfiles)

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'junegunn/vim-easy-align'
Plug 'flazz/vim-colorschemes'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-obsession'
Plug 'PProvost/vim-ps1'
" Plug 'scrooloose/syntastic'
Plug 'w0rp/ale'
Plug 'scrooloose/nerdtree'
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
Plug 'https://gist.github.com/1171559.git', Gist('next_motion_mapping')
Plug 'tpope/vim-surround'          
Plug 'felixhummel/setcolors.vim'
Plug 'wellle/targets.vim'

call plug#end()

" EasyAlign mappings
"  Markdown Table mappings
"  'tab' aligns selected markdown table
au FileType markdown vmap <tab> :EasyAlign*<Bar><Enter>\
"  '|' selects and aligns markdown table
au FileType markdown map <Bar> vip :EasyAlign*<Bar><Enter>

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
"
" " Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Key mappings to move lines
" http://vim.wikia.com/wiki/Moving_lines_up_or_down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Key mappings to more easily navigate tabs
nnoremap <A-h> :tabp<Enter>
nnoremap <A-l> :tabn<Enter>

" Auto-reload *rc files on save
if has ('autocmd') " Remain compatible with earlier versions
 augroup vimrc     " Source vim configuration upon save
    autocmd! BufWritePost $MYVIMRC source % | echom "Reloaded " . $MYVIMRC | redraw
    autocmd! BufWritePost $MYGVIMRC if has('gui_running') | so % | echom "Reloaded " . $MYGVIMRC | endif | redraw
  augroup END
endif " has autocmd

" Key mappings for tab navigation
" http://vim.wikia.com/wiki/Using_tab_pages
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
nnoremap <silent> <A-Left> :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
nnoremap <silent> <A-Right> :execute 'silent! tabmove ' . (tabpagenr()+1)<CR>

set relativenumber
set number
colorscheme znake 

set pastetoggle=<F3>

" let g:syntastic_cloudformation_checkers = ['cfn_lint']
let g:ale_completion_enabled = 1
