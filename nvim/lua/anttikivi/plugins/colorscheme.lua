return {
  {
    "anttikivi/brunch.nvim",
    dev = true,
    lazy = false,
    enabled = not vim.g.true_colors,
    config = function()
      require("brunch").load()
      vim.cmd.colorscheme "brunch"
    end,
    priority = 1000,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    enabled = vim.g.true_colors and vim.g.color_scheme == "catppuccin",
    opts = {
      flavour = "auto",
      background = {
        dark = vim.g.color_scheme_dark_variant,
        light = vim.g.color_scheme_light_variant,
      },
      transparent_background = false,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme "catppuccin"
    end,
    priority = 1000,
  },
  {
    "rose-pine/neovim",
    lazy = false,
    enabled = vim.g.true_colors and vim.g.color_scheme == "rose-pine",
    opts = {
      variant = "auto",
      dark_variant = vim.g.color_scheme_dark_variant,
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme "rose-pine"
    end,
  },
  {
    "cormacrelf/dark-notify",
    event = "VeryLazy",
    config = function()
      require("dark_notify").run()
    end,
  },
}
