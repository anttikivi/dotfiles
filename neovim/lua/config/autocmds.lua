local function augroup(name)
    return vim.api.nvim_create_augroup("anttikivi_" .. name, { clear = true })
end

-- Highlight on yank.
---@diagnostic disable-next-line: param-type-mismatch
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank()
    end,
})
