local config = require("config")

local M = {}

function M.pack_spec()
    local ret = {
        { src = "https://github.com/f-person/auto-dark-mode.nvim" },
    }
    if config.colorscheme == "catppuccin" then
        ret[#ret + 1] = { src = "https://github.com/catppuccin/nvim", name = "catppuccin" }
    elseif config.colorscheme == "lucid" then
        -- ret[#ret + 1] = { src = "file:///Users/anttikivi/Projects/lucid.nvim" }
    elseif config.colorscheme == "tokyonight" then
        ret[#ret + 1] = { src = "https://github.com/folke/tokyonight.nvim" }
    elseif config.colorscheme == "rose-pine" then
        ret[#ret + 1] = { src = "https://github.com/rose-pine/neovim", name = "rose-pine" }
    else
        vim.notify(("Invalid color scheme %q"):format(config.colorscheme), vim.log.levels.ERROR)
    end

    return ret
end

function M.init()
    require("auto-dark-mode").setup({ update_interval = 5000 })

    if config.colorscheme == "catppuccin" then
        require("catppuccin").setup({
            flavour = "auto",
            background = {
                dark = config.colorscheme_dark_variant --[[@as CtpFlavor]],
                light = config.colorscheme_light_variant --[[@as CtpFlavor]],
            },
            integrations = {
                blink_cmp = config.cmp == "blink" and {
                    style = "bordered",
                } or false,
                cmp = config.cmp == "nvim-cmp",
                gitsigns = true,
                harpoon = true,
                markdown = true,
                mason = true,
                native_lsp = {
                    enabled = true,
                    underlines = {
                        errors = { "undercurl" },
                        hints = { "undercurl" },
                        warnings = { "undercurl" },
                        information = { "undercurl" },
                    },
                },
                semantic_tokens = true,
                telescope = {
                    enabled = config.picker == "telescope",
                },
                treesitter = true,
            },
        })
    elseif config.colorscheme == "tokyonight" then
        ---@diagnostic disable-next-line: missing-fields
        require("tokyonight").setup({
            style = config.colorscheme_dark_variant,
            light_style = config.colorscheme_light_variant,
        })
    elseif config.colorscheme == "rose-pine" then
        require("rose-pine").setup({})
    end

    vim.cmd.colorscheme(config.colorscheme)
end

return M
