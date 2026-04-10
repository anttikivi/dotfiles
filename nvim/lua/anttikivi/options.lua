vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = false
vim.g.netrw_list_hide = "^\\.DS_Store$"
vim.g.root_spec = { "lsp", { ".git" }, "cwd" }

vim.opt.rtp:prepend("~/src/personal/granite.nvim")

vim.opt.autocomplete = true
vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = "80"
vim.opt.completeopt = "menu,menuone,noinsert,popup"
vim.opt.expandtab = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.formatexpr = "v:lua.formatexpr()"
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
