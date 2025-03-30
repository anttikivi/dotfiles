return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
    },
    event = "LazyFile",
  },
  {
    "ThePrimeagen/harpoon",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
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
      { "nvim-lua/plenary.nvim" },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
        build = "make",
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
    },
    enabled = vim.g.finder == "telescope",
    opts = function()
      local actions = require("telescope.actions")

      return {
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = actions.close,
            },
          },
        },
        extensions = {
          ["ui-select"] = require("telescope.themes").get_dropdown(),
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      telescope.setup(opts)
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
    cmd = "Telescope",
    keys = function()
      local builtin = require("telescope.builtin")

      return {
        { "<leader>ff", builtin.find_files, desc = "Find files" },
        { "<leader>sg", builtin.live_grep, desc = "Grep" },
      }
    end,
  },
  {
    "folke/todo-comments.nvim",
    opts = {},
    event = "LazyFile",
    cmd = { "TodoTrouble", "TodoTelescope" },
  },
}
