if exists('b:did_ftplugin_terraform')
  finish
endif
let b:did_ftplugin_terraform = 1

setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal textwidth=0
setlocal colorcolumn=100

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal expandtab< shiftwidth< softtabstop< tabstop< textwidth< '
    \ .. 'colorcolumn<'
