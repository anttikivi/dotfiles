vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.netrw_list_hide = "^\\.DS_Store$"

-- See: https://neovim.io/doc/user/options.html or :help options.

vim.schedule(function()
  vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

vim.opt.colorcolumn = "80"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.guicursor = ""
vim.opt.ignorecase = true
vim.opt.laststatus = 3
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 4
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.showbreak = "+++ "
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.tabstop = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.timeoutlen = 1000 -- currently the default value
vim.opt.title = true
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 100
vim.opt.wrap = true
