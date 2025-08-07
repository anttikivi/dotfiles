local config = require("config")

-- Make up and down take line wrapping into account.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Return to file explorer.
if config.file_explorer == "netrw" then
    vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Resume to file explorer" })
elseif config.file_explorer == "oil" then
    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Resume to file explorer" })
end

-- Clear highlights on search and stop snippets.
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
    vim.cmd("noh")
    if vim.snippet then
        vim.snippet.stop()
    end
    return "<esc>"
end, { expr = true, desc = "Clear highlights and stop snippet" })

-- Better indenting.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

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

-- Paste without overwriting the clipboard.
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting the clipboard" })

-- Delete without yanking.
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Run tmux-sessionizer.
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
