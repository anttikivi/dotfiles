local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup {
  spec = {
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      ---@type LazyVimOptions
      opts = {
        icons = {
          misc = {
            dots = "…",
          },
          diagnostics = {
            Error = "E ",
            Warn = "W ",
            Hint = "H ",
            Info = "I ",
          },
          git = {
            added = "+ ",
            modified = "~ ",
            removed = "- ",
          },
          kinds = {
            Array = "∀ ",
            Boolean = "󰨙 ",
            Class = "⎇ ",
            Codeium = "󰘦 ",
            Color = "🎨 ",
            Control = "⌘ ",
            Collapsed = "> ",
            Constant = "󰏿 ",
            Constructor = "⚙︎ ",
            Copilot = "🚀 ",
            Enum = "✧ ",
            EnumMember = "✦ ",
            Event = "☇ ",
            Field = "∈ ",
            File = "📁 ",
            Folder = "📂 ",
            Function = "󰊕 ",
            Interface = "⌥ ",
            Key = "⚿ ",
            Keyword = "⎃ ",
            Method = "󰊕 ",
            Module = "☒ ",
            Namespace = "󰦮 ",
            Null = "∅ ",
            Number = "󰎠 ",
            Object = "󰘦 ",
            Operator = "⥲ ",
            Package = "☒ ",
            Property = "∈ ",
            Reference = "➾ ",
            Snippet = "⿳ ",
            String = "⎂ ",
            Struct = "󰆼 ",
            TabNine = "󰏚 ",
            Text = "⌨︎ ",
            TypeParameter = "∁ ",
            Unit = "1 ",
            Value = "⎂ ",
            Variable = "󰀫 ",
          },
        },
      },
    },
    { import = "lazyvim.plugins.extras.coding.copilot" },
    { import = "lazyvim.plugins.extras.formatting.black" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "lazyvim.plugins.extras.lang.cmake" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.terraform" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "brunch" } },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  ui = {
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
}
