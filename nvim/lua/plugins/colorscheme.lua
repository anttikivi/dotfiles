return {
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      update_interval = 1000, -- TODO: This value works on macOS.
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    enabled = vim.g.colorscheme == "catppuccin",
    opts = {
      flavour = "auto",
      background = {
        dark = vim.g.colorscheme_dark_variant,
        light = vim.g.colorscheme_light_variant,
      },
      integrations = {
        blink_cmp = vim.g.cmp_engine == "blink",
      },
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    enabled = vim.g.colorscheme == "rose-pine",
    opts = {
      variant = "auto",
      dark_variant = vim.g.colorscheme_dark_variant,
    },
  },
}
