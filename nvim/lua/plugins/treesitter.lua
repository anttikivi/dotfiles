return {
  {
    "nvim-treesitter/nvim-treesitter",
    ---@module "nvim-treesitter"
    ---@type TSConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
      },
    },
    main = "nvim-treesitter.configs",
    lazy = vim.fn.argc(-1) == 0,
    event = { "LazyFile", "VeryLazy" },
    build = ":TSUpdate",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  },
}
