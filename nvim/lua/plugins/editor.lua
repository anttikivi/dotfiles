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
    keys = function(_, keys)
      local builtin = require("telescope.builtin")

      return {
        { "<leader>ff", builtin.find_files, desc = "Find files" },
        { "<leader>sg", builtin.live_grep, desc = "Grep" },
      }
    end,
  },
}
