setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal textwidth=0
setlocal colorcolumn=80
setlocal formatoptions-=t
setlocal formatoptions+=croq

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal expandtab< shiftwidth< softtabstop< tabstop< textwidth< '
    \ .. 'colorcolumn< formatoptions<'
