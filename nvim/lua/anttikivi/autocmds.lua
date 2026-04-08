vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    group = "highlight_yank",
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_augroup("pack_changed", { clear = true })
vim.api.nvim_create_autocmd("PackChanged", {
    group = "pack_changed",
    callback = function(ev)
        if ev.data.spec.name == "mason.nvim" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("mason")
                vim.cmd("MasonUpdate")
            end
        elseif ev.data.spec.name == "nvim-treesitter" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("nvim-treesitter")
                vim.cmd("TSUpdate")
            end
        end
    end,
})
