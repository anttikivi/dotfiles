return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      lazygit = {
        enabled = true,
      },
    },
    lazy = false,
  },
}
