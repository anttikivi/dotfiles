local util = require("dot.util")

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = util.augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank()
    end,
})

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local last_lsp_progress = 0

-- Show LSP progress.
vim.api.nvim_create_autocmd("LspProgress", {
    group = util.augroup("lsp_progress"),
    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
    callback = function(ev)
        local now = vim.uv.now()
        if ev.data.params.value.kind ~= "end" and (now - last_lsp_progress) < 100 then
            return
        end
        last_lsp_progress = now
        vim.notify(
            -- TODO: This is not an optimal solution but kinda nice for now.
            ev.data.params.value.kind == "end" and " Workspace loaded"
                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] .. " " .. vim.lsp.status(),
            vim.log.levels.INFO
        )
    end,
})

-- Run required updates for plugins when they are updated.
vim.api.nvim_create_autocmd("PackChanged", {
    group = util.augroup("pack_changed"),
    callback = function(ev)
        if ev.data.spec.name == "mason.nvim" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                vim.cmd("MasonUpdate")
            end
        elseif ev.data.spec.name == "nvim-treesitter" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                vim.cmd("TSUpdate")
            end
        end
    end,
})
