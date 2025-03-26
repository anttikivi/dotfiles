local telescope_builtin = require("telescope.builtin")

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
        build = "make",
      },
    },
    enabled = vim.g.finder == "telescope",
    opts = {},
    cmd = "Telescope",
    keys = {
      { "<leader>ff", telescope_builtin.find_files, desc = "Find files" },
      { "<leader>sg", telescope_builtin.live_grep, desc = "Grep" },
    },
  },
}
