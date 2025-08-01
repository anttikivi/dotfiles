vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = false
vim.g.netrw_list_hide = "^\\.DS_Store$"

-- Use the completion engine for the AI suggestions.
---@type boolean
vim.g.ai_cmp_enabled = true

---@type boolean
vim.g.ai_enabled = true

---@type AiEngine
vim.g.ai_engine = "supermaven"

-- Helper for determining the AI in the completion engine is actually enabled.
---@type boolean
vim.g.ai_cmp = vim.g.ai_cmp_enabled and vim.g.ai_enabled

---@type CmpEngine
vim.g.cmp_engine = "nvim-cmp"

---@type Colorscheme
vim.g.colorscheme = vim.env.COLOR_SCHEME --[[@as Colorscheme]]

---@type ColorschemeDarkVariant
vim.g.colorscheme_dark_variant = vim.env.COLOR_SCHEME_DARK_VARIANT --[[@as ColorschemeDarkVariant]]

---@type ColorschemeLightVariant
vim.g.colorscheme_light_variant = vim.env.COLOR_SCHEME_LIGHT_VARIANT --[[@as ColorschemeLightVariant]]

---@type boolean
vim.g.custom_statusline = true

---@type boolean
vim.g.eslint_auto_format = false

---@type Finder
vim.g.finder = "telescope"

---@type FileExplorer
vim.g.file_explorer = "oil"

---@type boolean
vim.g.lazygit_enabled = false

---@type "intelephense" | "phpactor"
vim.g.php_lsp = "intelephense"

---@type boolean
vim.g.prettier_needs_config = false

---@type "bacon-ls" | "rust-analyzer"
vim.g.rust_diagnostics = "bacon-ls"

-- Root directory detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string | string[]`
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- See: https://neovim.io/doc/user/options.html or :help options.

-- vim.schedule(function()
--   vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
-- end)

vim.opt.clipboard = "unnamedplus"

vim.opt.colorcolumn = "80"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.formatexpr = "v:lua.require'util.format'.formatexpr()"
vim.opt.guicursor = ""
vim.opt.ignorecase = true
vim.opt.laststatus = 3
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.number = true
vim.opt.pumblend = 10
vim.opt.relativenumber = true
vim.opt.scrolloff = 4
vim.opt.shiftround = true
vim.opt.shiftwidth = 0
vim.opt.showbreak = "> "
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitkeep = "screen"
vim.opt.splitright = true

if vim.g.custom_statusline then
  vim.opt.statusline = require("util.statusline").get()
end

-- vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.timeoutlen = 1000 -- currently the default value
vim.opt.title = true
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 100
vim.opt.wrap = true
