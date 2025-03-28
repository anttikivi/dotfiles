if vim.loader then
  vim.loader.enable()
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.autocmds")
require("config.keymaps")

require("util.event").setup()

-- Formatting setup
local format = require("util.format")

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("util.format", {}),
  callback = function(event)
    format({ buf = event.buf })
  end,
})
vim.api.nvim_create_user_command("Format", function()
  format({ force = true })
end, { desc = "Format selection or buffer" })
vim.api.nvim_create_user_command("FormatInfo", function()
  format.info()
end, { desc = "Show info about the formatters for the current buffer" })

require("util.root").setup()

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = false },
  change_detection = { enabled = true, notify = false },
})

vim.cmd.colorscheme(vim.g.colorscheme)
