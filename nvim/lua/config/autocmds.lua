local function augroup(name)
    return vim.api.nvim_create_augroup("anttikivi_" .. name, { clear = true })
end

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd("LspProgress", {
    group = augroup("lsp_progress"),
    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
    callback = function(ev)
        local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        vim.notify(
            -- TODO: This is not an optimal solution but kinda nice for now.
            ev.data.params.value.kind == "end" and " "
                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] .. " " .. vim.lsp.status(),
            vim.log.levels.INFO
        )
    end,
})
