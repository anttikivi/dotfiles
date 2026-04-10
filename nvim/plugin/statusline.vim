if exists('g:loaded_my_statusline')
  finish
endif
let g:loaded_my_statusline = 1

let s:vcs_cache = {}
let s:vcs_kinds = {}
let s:vcs_stale = {}
let s:buf_root_cache = {}

let s:root_jobs = {}
let s:job_meta = {}
let s:job_output = {}

function! s:GetColors() abort
  return luaeval('require("granite").colors[vim.o.background]')
endfunction

function! s:VcsHighlight(kind) abort
  if a:kind ==# 'jj'
    return 'StatusLineJjRev'
  endif

  if a:kind ==# 'git'
    return 'StatusLineGitBranch'
  endif

  return 'StatusLine'
endfunction

function! s:GetVcsRoot(buf) abort
  return luaeval(
      \   'require("anttikivi.root").vcs({
      \     buf = _A,
      \     normalize = true
      \   })',
      \   a:buf
      \ )
endfunction

function! s:GetCachedRoot(buf) abort
  if a:buf <= 0 || !bufexists(a:buf)
    return ''
  endif

  if has_key(s:buf_root_cache, a:buf)
    return s:buf_root_cache[a:buf]
  endif

  let l:root = s:GetVcsRoot(a:buf)
  let s:buf_root_cache[a:buf] = l:root
  return l:root
endfunction

function! s:SetWindowVcs(winid, label, kind) abort
  call setwinvar(a:winid, 'statusline_vcs', a:label)
  call setwinvar(a:winid, 'statusline_vcs_hl', s:VcsHighlight(a:kind))
endfunction


function! s:RefreshWindowsForRoot(root) abort
  let l:label = get(s:vcs_cache, a:root, '')
  let l:kind = get(s:vcs_kinds, a:root, '')

  for l:win in getwininfo()
    let l:buf = winbufnr(l:win.winid)

    if s:GetCachedRoot(l:buf) ==# a:root
      call s:SetWindowVcs(l:win.winid, l:label, l:kind)
    endif
  endfor

  redrawstatus
endfunction

function! s:BuildAsyncCommand(root) abort
  if empty(a:root)
    return #{ cmd: '', kind: '' }
  endif

  if isdirectory(a:root . '/.jj') && executable('jj')
    let l:tmpl = shellescape(
        \ 'local_bookmarks.map(|b| b.name()).join(" ")'
        \ )

    let l:cmd =
        \ 'out="$('
        \ . 'jj -R ' . shellescape(a:root) . ' log --no-graph'
        \ . ' -r @ -T ' . l:tmpl . ' 2>/dev/null'
        \ . ')"; '
        \ . '[ -n "${out}" ] || out=$('
        \ . 'jj -R ' . shellescape(a:root) . ' log --no-graph'
        \ . ' -r @- -T ' . l:tmpl . ' 2>/dev/null'
        \ . '); '
        \ . '[ -n "${out}" ] || out=$('
        \ . 'jj -R ' . shellescape(a:root) . ' log --no-graph'
        \ . ' -r @ -T change_id 2>/dev/null'
        \ . ' | cut -c1-8'
        \ . '); '
        \ . 'printf "%s" "${out}"'

    return #{ cmd: l:cmd, kind: 'jj' }
  endif

  if executable('git')
    return #{
        \ cmd: 'git -C ' . shellescape(a:root)
        \   . ' rev-parse --abbrev-ref HEAD 2>/dev/null',
        \ kind: 'git',
        \ }
  endif

  return #{ cmd: '', kind: '' }
endfunction

function! s:OnVcsStdout(jobid, data, event) abort
  let s:job_output[a:jobid] = a:data
endfunction

function! s:OnVcsExit(jobid, code, event) abort
  if !has_key(s:job_meta, a:jobid)
    return
  endif

  let l:meta = s:job_meta[a:jobid]
  call remove(s:job_meta, a:jobid)

  if has_key(s:root_jobs, l:meta.root)
    call remove(s:root_jobs, l:meta.root)
  endif

  let l:lines = get(s:job_output, a:jobid, [])
  if has_key(s:job_output, a:jobid)
    call remove(s:job_output, a:jobid)
  endif

  let l:out = trim(join(l:lines, "\n"))
  let l:label = ''
  let l:kind = ''

  if l:meta.kind ==# 'jj'
    if !empty(l:out)
      let l:label = substitute(l:out, '%', '%%', 'g')
      let l:kind = 'jj'
    endif
  elseif l:meta.kind ==# 'git'
    if !empty(l:out)
      let l:label = substitute(l:out, '%', '%%', 'g')
    endif
    let l:kind = 'git'
  endif

  let s:vcs_cache[l:meta.root] = l:label
  let s:vcs_kinds[l:meta.root] = l:kind

  if has_key(s:vcs_stale, l:meta.root)
    call remove(s:vcs_stale, l:meta.root)
  endif

  call s:RefreshWindowsForRoot(l:meta.root)
endfunction

function! s:StartAsyncRefresh(root) abort
  if empty(a:root) || has_key(s:root_jobs, a:root)
    return
  endif

  let l:spec = s:BuildAsyncCommand(a:root)

  if empty(l:spec.cmd)
    let s:vcs_cache[a:root] = ''
    let s:vcs_kinds[a:root] = ''
    if has_key(s:vcs_stale, a:root)
      call remove(s:vcs_stale, a:root)
    endif
    call s:RefreshWindowsForRoot(a:root)
    return
  endif

  let l:jobid = jobstart(
      \ ['sh', '-c', l:spec.cmd],
      \ #{
      \   stdout_buffered: v:true,
      \   on_stdout: function(expand('<SID>') . 'OnVcsStdout'),
      \   on_exit: function(expand('<SID>') . 'OnVcsExit'),
      \ }
      \ )

  if l:jobid <= 0
    return
  endif

  let s:root_jobs[a:root] = l:jobid
  let s:job_meta[l:jobid] = #{
      \ root: a:root,
      \ kind: l:spec.kind,
      \ }
endfunction

function! s:RefreshWindow(buf) abort
  if a:buf <= 0 || !bufexists(a:buf)
    return
  endif

  let l:root = s:GetCachedRoot(a:buf)
  let l:winid = win_getid()

  if empty(l:root)
    call s:SetWindowVcs(l:winid, '', '')
    return
  endif

  if !isdirectory(l:root . '/.jj')
    let l:head = getbufvar(a:buf, 'gitsigns_head', '')

    if !empty(l:head)
      let l:head = substitute(l:head, '%', '%%', 'g')
      let s:vcs_cache[l:root] = l:head
      let s:vcs_kinds[l:root] = 'git'

      if has_key(s:vcs_stale, l:root)
        call remove(s:vcs_stale, l:root)
      endif
    endif
  endif

  if has_key(s:vcs_cache, l:root)
    call s:SetWindowVcs(
        \ l:winid,
        \ s:vcs_cache[l:root],
        \ get(s:vcs_kinds, l:root, '')
        \ )

    if has_key(s:vcs_stale, l:root)
      call s:StartAsyncRefresh(l:root)
    endif

    return
  endif

  call s:SetWindowVcs(l:winid, '', '')
  call s:StartAsyncRefresh(l:root)
endfunction

function! s:MarkVcsStaleForBuffer(buf) abort
  let l:root = s:GetCachedRoot(a:buf)

  if !empty(l:root)
    let s:vcs_stale[l:root] = v:true
  endif
endfunction

function! s:InvalidateRootForBuffer(buf) abort
  if has_key(s:buf_root_cache, a:buf)
    call remove(s:buf_root_cache, a:buf)
  endif
endfunction

function! s:InvalidateAllRoots() abort
  let s:buf_root_cache = {}
endfunction

function! s:SetHighlights() abort
  let l:colors = s:GetColors()

  execute 'highlight StatusLineGitBranch guifg=' . l:colors.bg_light
      \ . ' guibg=' . l:colors.red
  execute 'highlight StatusLineJjRev guifg=' . l:colors.bg_light
      \ . ' guibg=' . l:colors.blue
endfunction

function! s:Statusline() abort
  let l:winid = get(g:, 'statusline_winid', win_getid())
  let l:vcs = getwinvar(l:winid, 'statusline_vcs', '')
  let l:hl = getwinvar(l:winid, 'statusline_vcs_hl', 'StatusLine')

  let l:left = []
  let l:right = []

  call add(l:left, '%<')

  if !empty(l:vcs)
    call add(l:left, '%#' . l:hl . '# ' . l:vcs . ' %* ')
  endif

  call add(l:left, '%f %h%w%m%r')
  call add(l:left, '%{get(b:,"gitsigns_status","")}')
  call add(l:left, '%{v:lua.require("vim._core.util").term_exitcode()}')

  call add(l:right, '%{% &showcmdloc == "statusline" ? "%-10.S " : "" %}')
  call add(
      \ l:right,
      \ '%{% exists("b:keymap_name") ? "<"..b:keymap_name.."> " : "" %}'
      \ )
  call add(l:right, '%{% &busy > 0 ? "◐ " : "" %}')
  call add(
      \ l:right,
      \ '%{%luaeval("'
      \ . '('
      \ . 'package.loaded[\"vim.diagnostic\"]'
      \ . ' and next(vim.diagnostic.count())'
      \ . ' and vim.diagnostic.status() .. \" \"'
      \ . ')'
      \ . ' or \"\"'
      \ . '")'
      \ . '%}'
      \ )
  call add(
      \ l:right,
      \ '%{% &ruler'
      \ . ' ? (&rulerformat == "" ? "%-14.(%l,%c%V%) %P" : &rulerformat )'
      \ . ' : "" %}'
      \ )

  return join(l:left, '') . '%=' . join(l:right, '')
endfunction

call s:SetHighlights()

" Current default statusline:
" %<%f %h%w%m%r %{% v:lua.require('vim._core.util').term_exitcode() %}%=%{% luaeval('(package.loaded[''vim.ui''] and vim.api.nvim_get_current_win() == tonumber(vim.g.actual_curwin or -1) and vim.ui.progress_status()) or '''' ')%}%{% &showcmdloc == 'statusline' ? '%-10.S ' : '' %}%{% exists('b:keymap_name') ? '<'..b:keymap_name..'> ' : '' %}%{% &busy > 0 ? '◐ ' : '' %}%{% luaeval('(package.loaded[''vim.diagnostic''] and next(vim.diagnostic.count()) and vim.diagnostic.status() .. '' '') or '''' ') %}%{% &ruler ? (&rulerformat == '' ? '%-14.(%l,%c%V%) %P' : &rulerformat ) : '' %}

let &statusline = '%!' . expand('<SID>') . 'Statusline()'

call s:RefreshWindow(bufnr('%'))

augroup MyStatusline
  autocmd!
  autocmd ColorScheme * call <SID>SetHighlights() | redrawstatus
  autocmd DiagnosticChanged * redrawstatus
  autocmd LspAttach *
      \ call <SID>InvalidateRootForBuffer(str2nr(expand('<abuf>')))
      \ | call <SID>RefreshWindow(str2nr(expand('<abuf>')))
      \ | redrawstatus
  autocmd VimEnter,WinEnter,BufEnter,BufWinEnter *
      \ call <SID>InvalidateRootForBuffer(bufnr('%'))
      \ | call <SID>RefreshWindow(bufnr('%'))
      \ | redrawstatus
  autocmd BufWritePost *
      \ call <SID>MarkVcsStaleForBuffer(bufnr('%'))
      \ | call <SID>RefreshWindow(bufnr('%'))
      \ | redrawstatus
  autocmd FocusGained *
      \ call <SID>MarkVcsStaleForBuffer(bufnr('%'))
      \ | call <SID>RefreshWindow(bufnr('%'))
      \ | redrawstatus
  autocmd DirChanged *
      \ call <SID>InvalidateAllRoots()
      \ | call <SID>MarkVcsStaleForBuffer(bufnr('%'))
      \ | call <SID>RefreshWindow(bufnr('%'))
      \ | redrawstatus
  autocmd BufFilePost *
      \ call <SID>InvalidateRootForBuffer(bufnr('%'))
      \ | call <SID>RefreshWindow(bufnr('%'))
      \ | redrawstatus
  autocmd BufDelete,BufWipeout *
      \ call <SID>InvalidateRootForBuffer(str2nr(expand('<abuf>')))
augroup END
