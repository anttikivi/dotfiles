local config = require("config")

-- Return to file explorer.
if config.file_explorer == "netrw" then
    vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Resume to file explorer" })
elseif config.file_explorer == "oil" then
    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Resume to file explorer" })
else
    vim.notify("[keymaps] invalid file explorer option", vim.log.levels.WARN)
end
