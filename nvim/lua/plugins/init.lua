return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      bigfile = { enabled = true },
      lazygit = {
        enabled = true,
      },
      quickfile = { enabled = true },
    },
    lazy = false,
  },
}
