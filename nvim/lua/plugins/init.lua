return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "folke/snacks.nvim",
    version = "^2.22.0",
    priority = 1000,
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Toggle keymaps
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.inlay_hints():map("<leader>uh")
        end,
      })
    end,
    opts = {
      bigfile = { enabled = true },
      indent = { enabled = true },
      lazygit = {
        enabled = vim.g.lazygit_enabled,
      },
      quickfile = { enabled = true },
    },
  },
}
