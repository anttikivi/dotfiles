if vim.loader and vim.loader.enable then
    vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = false
vim.g.netrw_list_hide = "^\\.DS_Store$"

---@type boolean
vim.g.autoformat = true

---@type "native" | "nvim-cmp"
vim.g.cmp = "nvim-cmp"

---@type "netrw" | "oil"
vim.g.file_explorer = "oil"

---@type boolean
vim.g.enable_icons = false

---@type boolean
vim.g.enable_statusline = true

---@type integer
vim.g.formatting_timeout_ms = 3000

---@type "telescope"
vim.g.picker = "telescope"

vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = "80"
vim.opt.completeopt = "menu,menuone,noselect,popup"
vim.opt.expandtab = true
vim.opt.guicursor = ""
vim.opt.ignorecase = true
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.showbreak = "> "
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.title = true

require("config.autocmds")
require("config.keymaps")

local pack_specs = {
    {
        src = "https://github.com/anttikivi/lucid.nvim",
        version = "b8dac7949c93a824e353bbd24f188b27ebdf8512",
    },
    {
        src = "https://github.com/anttikivi/nvim-lint",
        version = "386ca59429b0b033c45cff8efc0902445a1d6173",
    },
    {
        src = "https://github.com/f-person/auto-dark-mode.nvim",
        version = "e300259ec777a40b4b9e3c8e6ade203e78d15881",
    },
    {
        src = "https://github.com/folke/lazydev.nvim",
        version = vim.version.range("1.10.0"),
    },
    {
        src = "https://github.com/lewis6991/gitsigns.nvim",
        version = vim.version.range("2.0.0"),
    },
    {
        src = "https://github.com/mason-org/mason.nvim",
        version = vim.version.range("2.2.1"),
    },
    {
        src = "https://github.com/nvim-lua/plenary.nvim",
        version = "b9fd5226c2f76c951fc8ed5923d85e4de065e509",
    },
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "81aca2f9815e26f638f697df1d828ca290847b64",
    },
    {
        src = "https://github.com/stevearc/conform.nvim",
        version = vim.version.range("9.1.0"),
    },
    {
        src = "https://github.com/ThePrimeagen/harpoon",
        version = "87b1a3506211538f460786c23f98ec63ad9af4e5",
    },
}

if vim.g.cmp == "nvim-cmp" then
    vim.list_extend(pack_specs, {
        {
            src = "https://github.com/hrsh7th/nvim-cmp",
            version = "da88697d7f45d16852c6b2769dc52387d1ddc45f",
        },
        {
            src = "https://github.com/hrsh7th/cmp-nvim-lsp",
            version = "cbc7b02bb99fae35cb42f514762b89b5126651ef",
        },
        {
            src = "https://github.com/hrsh7th/cmp-buffer",
            version = "b74fab3656eea9de20a9b8116afa3cfc4ec09657",
        },
        {
            src = "https://github.com/hrsh7th/cmp-path",
            version = "c642487086dbd9a93160e1679a1327be111cbc25",
        },
    })
end

if vim.g.file_explorer == "oil" then
    pack_specs[#pack_specs + 1] = {
        src = "https://github.com/stevearc/oil.nvim",
        version = vim.version.range("2.15.0"),
    }
end

if vim.g.picker == "telescope" then
    vim.list_extend(pack_specs, {
        {
            src = "https://github.com/nvim-telescope/telescope.nvim",
            version = vim.version.range("0.2.1"),
        },
        {
            src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
            version = "6fea601bd2b694c6f2ae08a6c6fab14930c60e2c",
        },
    })
end

vim.pack.add(pack_specs)

require("config.pack").setup()
require("config.root").setup()
require("config.languages.init").setup()
require("config.cmp").setup()
require("config.mason").setup()
require("config.lsp").setup()
require("config.diagnostics").setup()
require("config.lint").setup()
require("config.treesitter").setup()
require("config.format").setup()
require("config.explorer").setup()
require("config.picker").setup()
require("config.harpoon").setup()
require("config.ui").setup()

require("auto-dark-mode").setup({ update_interval = 5000 })
vim.cmd.colorscheme("lucid")
