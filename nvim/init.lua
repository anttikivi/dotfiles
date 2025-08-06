local colors = require("colors")
local config = require("config")

require("config.options")
require("config.autocmds")
require("config.keymaps")

vim.pack.add({
    colors.colorscheme_plugin_spec(),
    { src = "https://github.com/f-person/auto-dark-mode.nvim" },
    { src = "https://github.com/folke/lazydev.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/Saghen/blink.cmp",                version = vim.version.range("^1.6.0") },
    { src = "https://github.com/stevearc/oil.nvim" },
})

require("lsp").init()
require("treesitter")
require("blink.cmp").setup({
    keymap = { preset = 'default' },
    sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100,
            },
        },
    },
})

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

require("lazydev").setup({
    library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
})

colors.init()
