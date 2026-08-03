if exists('b:did_ftplugin_markdown')
  finish
endif
let b:did_ftplugin_markdown = 1

setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal textwidth=0
setlocal colorcolumn=80

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
let b:undo_ftplugin ..= (empty(b:undo_ftplugin) ? '' : ' | ')
    \ .. 'setlocal expandtab< shiftwidth< softtabstop< tabstop< textwidth< '
    \ .. 'colorcolumn< | autocmd! markdown_autofmt * <buffer>'

function! s:HasPrettierConfig() abort
  let l:prettier_files = [
        \ '.prettierrc', '.prettierrc.json', 
        \ '.prettierrc.yml', '.prettierrc.yaml',
        \ '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.mjs',
        \ 'prettier.config.js', 'prettier.config.cjs', 'prettier.config.mjs'
        \ ]
  let l:dir = expand('%:p:h')
  for l:file in l:prettier_files
    if !empty(findfile(l:file, l:dir . ';'))
      return 1
    endif
  endfor
  return 0
endfunction

function! s:GetLocalOxfmtConfig() abort
  let l:oxfmt_files = ['.oxfmtrc', '.oxfmtrc.json', 'oxfmt.json', '.oxfmt.json']
  let l:dir = expand('%:p:h')
  for l:file in l:oxfmt_files
    let l:found = findfile(l:file, l:dir . ';')
    if !empty(l:found)
      return l:found
    endif
  endfor
  return ''
endfunction

function! s:FormatMarkdown() abort
  if s:HasPrettierConfig()
    return
  endif

  let l:local_config = s:GetLocalOxfmtConfig()

  if !empty(l:local_config)
    let l:local_bin = findfile('node_modules/.bin/oxfmt', expand('%:p:h') . ';')
    if !empty(l:local_bin)
      let l:bin = fnamemodify(l:local_bin, ':p')
    elseif executable('oxfmt')
      let l:bin = 'oxfmt'
    else
      return
    endif
    let l:config_flag = ''
  else
    if !executable('oxfmt')
      return
    endif
    let l:bin = 'oxfmt'
    let l:config_flag = 
          \ '--config ' . 
          \ shellescape(expand('~/src/personal/dotfiles/oxfmtrc.json'))
  endif

  let l:file_path = shellescape(expand('%:p'))
  let l:cmd = 
        \ shellescape(l:bin) . ' ' . 
        \ l:config_flag . 
        \ ' --stdin-filepath ' . l:file_path
  let l:content = getline(1, '$')
  let l:formatted = systemlist(l:cmd, l:content)

  if v:shell_error == 0 && !empty(l:formatted)
    let l:view = winsaveview()
    silent %delete _
    call setline(1, l:formatted)
    call winrestview(l:view)
  else
    echohl ErrorMsg | echo "oxfmt formatting failed" | echohl None
  endif
endfunction

augroup markdown_autofmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call s:FormatMarkdown()
augroup END
