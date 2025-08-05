return {
  {
    "f-person/auto-dark-mode.nvim",
    commit = "c31de126963ffe9403901b4b0990dde0e6999cc6", -- TODO: Check sometimes for updates.
    opts = {
      update_interval = 1000, -- TODO: This value works on macOS.
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    version = "^1.10.0",
    enabled = vim.g.colorscheme == "catppuccin",
    opts = {
      flavour = "auto",
      background = {
        dark = vim.g.colorscheme_dark_variant,
        light = vim.g.colorscheme_light_variant,
      },
      -- transparent_background = true,
      integrations = {
        blink_cmp = vim.g.cmp_engine == "blink",
      },
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    version = "^3.0.2",
    enabled = vim.g.colorscheme == "rose-pine",
    opts = {
      variant = "auto",
      dark_variant = vim.g.colorscheme_dark_variant,
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    enabled = vim.g.colorscheme == "tokyonight",
    opts = function()
      return {
        style = vim.g.colorscheme_dark_variant,
        light_style = vim.g.colorscheme_light_variant,
      }
    end,
  },
}
