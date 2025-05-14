return {
  {
    enabled = vim.g.cmp_engine == "blink",
    import = "plugins.cmp.blink",
  },
  {
    enabled = vim.g.cmp_engine == "nvim-cmp",
    import = "plugins.cmp.nvim_cmp",
  },
  {
    enabled = vim.g.ai_enabled,
    import = "plugins.optional.copilot",
  },
  {
    "folke/lazydev.nvim",
    version = "^1.9.0",
    cmd = "LazyDev",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}
