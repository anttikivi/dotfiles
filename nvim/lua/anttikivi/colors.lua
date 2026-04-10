local granite = require("granite")

require("auto-dark-mode").setup({ update_interval = 5000 })

local colors = granite.colors[vim.o.background]

granite.setup({ transparent = true })
vim.api.nvim_set_hl(0, "SubstratumJjRev", { fg = colors.bg_light, bg = colors.blue })
vim.api.nvim_set_hl(0, "SubstratumGitBranch", { fg = colors.bg_light, bg = colors.red })
vim.cmd.colorscheme("granite")
