local config = require("config")

require("config.options")
require("config.autocmds")
require("config.keymaps")

local function colorscheme_plugin()
    if config.colorscheme == "catppuccin" then
        return { src = "https://github.com/catppuccin/nvim" }
    end
end

vim.pack.add({
    colorscheme_plugin(),
    { src = "https://github.com/f-person/auto-dark-mode.nvim" },
    { src = "https://github.com/folke/lazydev.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { src = "https://github.com/mason-org/mason.nvim" },
    -- TODO: Update tree-sitter to the 'main' branch.
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = 'master', },
    { src = "https://github.com/stevearc/oil.nvim" },
})

require("lsp")
require("treesitter")

if config.file_explorer == "oil" then
    require("oil").setup({
        default_file_explorer = true,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 2000,
        },
        watch_for_changes = true,
        view_options = {
            show_hidden = true,
            is_always_hidden = function(name)
                return name == ".." or name == ".DS_Store"
            end,
        },
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
