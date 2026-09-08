let b:prettier_ft_default_args = {
  \ 'parser': 'css',
  \ }

augroup Prettier
  autocmd!
  if get(g:, 'prettier#autoformat', 0)
    autocmd BufWritePre *.css call prettier#Autoformat()
  endif
augroup end
