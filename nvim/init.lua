vim.g.did_install_default_menus = 1

if vim.loader and vim.loader.enable then
    vim.loader.enable()
end

require("anttikivi.options")
require("anttikivi.keymaps")
require("anttikivi.autocmds")

vim.pack.add({
    {
        src = "https://github.com/f-person/auto-dark-mode.nvim",
        version = "54058b4fe414bd64bd2904a6f8a63f1f14e3d8df",
    },
    "https://github.com/folke/lazydev.nvim",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mfussenegger/nvim-lint",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/stevearc/conform.nvim",
    "https://github.com/tpope/vim-vinegar",
})

vim.filetype.add({
    extension = {
        h = "c",
        tf = "opentofu",
        tfvars = "opentofu-vars",
    },
})

require("anttikivi.formatter").init()
require("anttikivi.lsp").init()

vim.diagnostic.config({
    virtual_lines = false,
    virtual_text = true,
})

require("anttikivi.root").init()
require("anttikivi.mason")
require("anttikivi.linter")
require("anttikivi.treesitter")
require("anttikivi.nav")
require("anttikivi.cmds")
require("anttikivi.colors")
