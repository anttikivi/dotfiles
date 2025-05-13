return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "folke/snacks.nvim",
    priority = 1000,
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
    lazy = false,
  },
}
