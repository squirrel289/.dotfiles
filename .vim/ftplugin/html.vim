autocmd BufWritePre * %s/\s\+$//e
let b:ale_fixers = {
\   'html': ['prettier'],
\}
