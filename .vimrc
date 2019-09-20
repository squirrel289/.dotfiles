filetype plugin indent on
" filetype on

set undofile " Maintain undo history between sessions

function! Gist(name)
    return { 'as': a:name, 'do': 'mkdir -p plugin: cp -f *.vim plugin/' }
endfunction         
                          
function! Download(url, output)
  if has('win32')
    silent! md a:output; (New-Object Net.WebClient).DownloadFile(a:url, $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(g:plugfile));
  endif
  if has('unix') || has('macunix')
    silent !curl -fLo a:output --create-dirs a:url 
  endif
endfunction

" Auto update plug.vim before we use it
if has('win32')
  let vimdir = $HOME.'/vimfiles/' 
  let plugfile = g:vimdir. 'autoload/plug.vim'
endif

if has('unix') || has('macunix')
  let vimdir = $HOME.'/.vim/' 
  let plugfile = g:vimdir. 'autoload/plug.vim'
endif

if empty(glob(g:plugfile))
  Download('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim', g:plugfile)
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let undodir = g:vimdir. 'undo'
let vimfiles = g:vimdir. 'plugged' 

" Let's save undo info!
if !isdirectory(g:vimdir)
    call mkdir(g:vimdir, "", 0770)
endif
if !isdirectory(g:undodir)
    call mkdir(g:undodir, "", 0700)
endif
if !isdirectory(g:vimfiles)
    call mkdir(g:vimfiles, "", 0770)
endif

let &undodir=g:undodir

set softtabstop=2
set shiftwidth=2
set expandtab

if has('macunix')
  let g:python_host_prog = '/System/Library/Frameworks/Python.framework/Versions/2.7/bin/python'
endif
" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(vimfiles)

" Plug 'scrooloose/syntastic'
Plug 'christianrondeau/vim-base64'
Plug 'PProvost/vim-ps1'
Plug 'airblade/vim-gitgutter'
Plug 'bling/vim-airline'
Plug 'easymotion/vim-easymotion'
Plug 'ervandew/supertab'
Plug 'felixhummel/setcolors.vim'
Plug 'flazz/vim-colorschemes'
Plug 'https://gist.github.com/1171559.git', Gist('next_motion_mapping')
Plug 'junegunn/vim-easy-align'
Plug 'moll/vim-node'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'pangloss/vim-javascript'
Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh \| UpdateRemotePlugins' }
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'shougo/unite.vim'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'w0rp/ale'
Plug 'prettier/vim-prettier'
Plug 'wellle/targets.vim'
Plug 'wesQ3/vim-windowswap'
Plug 'xavierchow/vim-swagger-preview'
Plug 'mbbill/undotree'

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
nnoremap ∆ :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

" Key mappings to more easily navigate tabs
nnoremap <A-h> :tabp<Enter>
nnoremap ˙ :tabp<Enter>
nnoremap <A-l> :tabn<Enter>
nnoremap ¬ :tabn<Enter>

nnoremap <C-h> <C-w><C-h>
nnoremap <C-l> <C-w><C-l>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
set splitbelow
set splitright

" Mode change mappings
tnoremap <Esc> <C-\><C-n>
nnoremap <Esc> :q<Enter>

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

let g:ale_completion_enabled = 1
