return {
  {
    "conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.nginx = { "prettier" }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nginx_language_server = {},
      },
    },
  },
}
