local config = require("dot.config")

-- Make up and down take line wrapping into account.
vim.keymap.set({ "n", "o", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "o", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Return to file explorer.
if config.file_explorer == "netrw" then
    vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Resume to file explorer" })
elseif config.file_explorer == "oil" then
    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Resume to file explorer" })
else
    vim.notify("[keymaps] invalid file explorer option", vim.log.levels.WARN)
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

-- Delete without yanking.
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })
