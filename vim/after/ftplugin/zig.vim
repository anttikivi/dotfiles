setlocal colorcolumn=100

let s:organize_imports = expand('<sfile>:p:h:h:h') . '/bin/zls-organize-imports'

function! s:OrganizeImports() abort
  if empty(expand('%:p')) || !executable(s:organize_imports)
    return
  endif

  let l:view = winsaveview()
  silent let l:organized = systemlist(
      \ shellescape(s:organize_imports) . ' ' . shellescape(expand('%:p')),
      \ bufnr(''))

  if v:shell_error != 0
    echohl ErrorMsg | echomsg 'ZLS import organization failed' | echohl None
  elseif l:organized !=# getline(1, '$')
    try | silent undojoin | catch | endtry
    call setline(1, l:organized)
    call deletebufline(bufnr(''), len(l:organized) + 1, '$')
  endif
  call winrestview(l:view)
endfunction

function! s:OrganizeImportsAndFormat() abort
  call s:OrganizeImports()
  if get(g:, 'zig_fmt_autosave', 1)
    call zig#fmt#Format()
  endif
endfunction

augroup vim-zig
  autocmd! BufWritePre <buffer>
  autocmd BufWritePre <buffer> call <SID>OrganizeImportsAndFormat()
augroup END

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal colorcolumn<'
