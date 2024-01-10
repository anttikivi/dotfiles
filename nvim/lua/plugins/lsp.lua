return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "ansible-lint",
        "shfmt",
        "stylua",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      ansiblels = {},
      astro = {},
      bashls = {},
      cssls = {},
      html = {},
      phpactor = {},
      stylelint_lsp = {},
      vimls = {},
    },
  },
}
