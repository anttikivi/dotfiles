require("auto-dark-mode").setup({ update_interval = 5000 })
require("catppuccin").setup({
    flavour = "auto",
    background = {
        light = "latte",
        dark = "mocha",
    },
    transparent_background = true,
})
vim.cmd.colorscheme("catppuccin")
