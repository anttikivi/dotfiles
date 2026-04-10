vim.cmd([[
" Manage arglist.
nnoremap <leader>aa <cmd>argadd %<cr>
nnoremap <leader>aD <cmd>argdelete %<cr>
nnoremap <leader>al <cmd>args<cr>
" These might also be built in.
nnoremap ]a <cmd>next<cr>
nnoremap [a <cmd>Next<cr>

" Really quick keymaps for jumping between arguments!
nnoremap <leader>1 <cmd>argument 1<cr>
nnoremap <leader>2 <cmd>argument 2<cr>
nnoremap <leader>3 <cmd>argument 3<cr>
nnoremap <leader>4 <cmd>argument 4<cr>
nnoremap <leader>5 <cmd>argument 5<cr>
nnoremap <leader>6 <cmd>argument 6<cr>
nnoremap <leader>7 <cmd>argument 7<cr>
nnoremap <leader>8 <cmd>argument 8<cr>
nnoremap <leader>9 <cmd>argument 9<cr>

" Take line wrapping into account when moving up and down.
nnoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'
onoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'

nnoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'
onoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'

" Keep selection after indenting.
xnoremap < <gv
xnoremap > >gv

" Delete without yanking.
nnoremap <leader>d "_d
vnoremap <leader>d "_d
]])

-- Clear highlights on search and stop snippets.
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
    vim.cmd("noh")
    if vim.snippet then
        vim.snippet.stop()
    end
    return "<esc>"
end, { expr = true, desc = "Clear highlights and stop snippet" })

-- Toggles
vim.keymap.set("n", "<leader>uh", function()
    -- TODO: This applies to the current buffer, should it be for all?
    local state = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not state, { bufnr = 0 })
    if state then
        vim.notify("Disabled inlay hints", vim.log.levels.INFO)
    else
        vim.notify("Enabled inlay hints", vim.log.levels.INFO)
    end
end)
