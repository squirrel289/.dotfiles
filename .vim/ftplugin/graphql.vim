let b:prettier_ft_default_args = {
  \ 'parser': 'graphql',
  \ }

augroup Prettier
  autocmd!
  if get(g:, 'prettier#autoformat', 0)
    autocmd BufWritePre *.graphql,*.gql call prettier#Autoformat()
  endif
augroup end
