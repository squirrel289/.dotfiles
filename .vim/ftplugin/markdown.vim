let b:prettier_ft_default_args = {
  \ 'parser': 'markdown',
  \ }

augroup Prettier
  autocmd!
  if get(g:, 'prettier#autoformat', 0)
    autocmd BufWritePre *.markdown,*.md,*.mdown,*.mkd,*.mkdn call prettier#Autoformat()
  endif
augroup end
