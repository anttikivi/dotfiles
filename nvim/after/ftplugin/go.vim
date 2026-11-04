setlocal colorcolumn=80,120

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal colorcolumn<'
