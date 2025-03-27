return {
  {
    "ThePrimeagen/harpoon",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local keys = {
        {
          "<C-h>",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Harpoon file",
        },
        {
          "<leader>h",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Toggle Harpoon quick menu",
        },
      }

      local ordinal = {
        "first",
        "second",
        "third",
        "fourth",
        "fifth",
        "sixth",
        "seventh",
        "eighth",
        "ninth",
      }
      for i, v in ipairs(ordinal) do
        table.insert(keys, {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = string.format("Switch to the %s Harpoon file", v),
        })
      end

      return keys
    end,
    branch = "harpoon2",
  },
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
    keys = function()
      local builtin = require("telescope.builtin")

      return {
        { "<leader>ff", builtin.find_files, desc = "Find files" },
        { "<leader>sg", builtin.live_grep, desc = "Grep" },
      }
    end,
  },
}
