local config = require("config")

local M = {}

function M.colorscheme_plugin_spec()
    if config.colorscheme == "catppuccin" then
        return { src = "https://github.com/catppuccin/nvim", name = "catppuccin" }
    elseif config.colorscheme == "tokyonight" then
        return { src = "https://github.com/folke/tokyonight.nvim" }
    end
end

function M.init()
    require("auto-dark-mode").setup({ update_interval = 1000 })

    if config.colorscheme == "catppuccin" then
        require("catppuccin").setup({
            flavour = "auto",
            background = {
                dark = config.colorscheme_dark_variant --[[@as CtpFlavor]],
                light = config.colorscheme_light_variant --[[@as CtpFlavor]],
            },
        })
    elseif config.colorscheme == "tokyonight" then
        require("tokyonight").setup({
            style = config.colorscheme_dark_variant,
            light_style = config.colorscheme_light_variant,
        })
    end

    vim.cmd.colorscheme(config.colorscheme)
end

return M
