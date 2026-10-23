setlocal colorcolumn=50,72
setlocal textwidth=72

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal colorcolumn< textwidth<'
