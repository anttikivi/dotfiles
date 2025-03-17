vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.netrw_list_hide = "^\\.DS_Store$"

-- See: https://neovim.io/doc/user/options.html or :help options.
local opt = vim.opt

vim.schedule(function()
  opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

opt.colorcolumn = "80"
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.guicursor = ""
opt.ignorecase = true
opt.laststatus = 3
opt.linebreak = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.number = true
opt.relativenumber = true
opt.scrolloff = 4
opt.shiftround = true
opt.shiftwidth = 2
opt.showbreak = "+++ "
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.tabstop = 2
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 1000 -- currently the default value
opt.title = true
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 100
opt.wrap = true
