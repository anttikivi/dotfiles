vim.opt.breakindent = true -- Enable break indent
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard
vim.opt.colorcolumn = "80" -- Highlight column 80
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.opt.formatoptions = "jcroqlnt" -- Set default format options
vim.opt.guicursor = "" -- Don't use the thin cursor
vim.opt.hlsearch = true -- Set highlight on search
vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.inccommand = "split" -- Incremental live preview of :s
vim.opt.list = true -- Show some invisible characters
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.mouse = "a" -- Enable mouse mode
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.scrolloff = 10 -- Lines of context
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.showmode = true -- Don't show the mode, since it's already in status line
vim.opt.sidescrolloff = 8 -- Columns of context
vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true -- Override the 'ignorecase' option if the search pattern contains upper case characters
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.tabstop = 2 -- Number of spaces tabs count for

local true_colors = require("anttikivi.util").true_colors

vim.opt.termguicolors = true_colors -- True color support
vim.opt.textwidth = 0 -- Maximum width of text
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.wrap = true -- Line wrap
