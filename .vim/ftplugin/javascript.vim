augroup Prettier
  autocmd!
  if get(g:, 'prettier#autoformat', 0)
    autocmd BufWritePre *.js,*.jsx,*.mjs call prettier#Autoformat()
  endif
augroup end
