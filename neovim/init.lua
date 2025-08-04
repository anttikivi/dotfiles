local config = require("config")

require("config.options")
require("config.autocmds")
require("config.keymaps")

vim.pack.add({
    { src = "https://github.com/f-person/auto-dark-mode.nvim" },
    { src = "https://github.com/folke/lazydev.nvim" },
})

if config.colorscheme == "catppuccin" then
    vim.pack.add({
        { src = "https://github.com/catppuccin/nvim" },
    })
end

require("auto-dark-mode").setup({ update_interval = 1000 })

if config.colorscheme == "catppuccin" then
    require("catppuccin").setup({
        flavour = "auto",
        background = {
            dark = config.colorscheme_dark_variant --[[@as CtpFlavor]],
            light = config.colorscheme_light_variant --[[@as CtpFlavor]],
        },
    })
end

vim.cmd.colorscheme(config.colorscheme)
