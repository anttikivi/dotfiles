setlocal colorcolumn=80
setlocal commentstring=/*\ %s\ */

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal colorcolumn<'
