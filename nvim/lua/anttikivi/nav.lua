local fzf = require("fzf-lua")

fzf.setup({ ui_select = true })

vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fr", fzf.resume, { desc = "Resume search" })
vim.keymap.set("n", "<leader>fa", fzf.args, { desc = "Search arguments" })
