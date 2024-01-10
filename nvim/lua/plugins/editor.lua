return {
  {
    "folke/flash.nvim",
    enabled = false,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      -- TODO: Maybe add keymaps later.
    },
  },
  {
    "ThePrimeagen/harpoon",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local harpoon = require "harpoon"
      harpoon:setup {}
    end,
    -- TODO: Update this when the branch is merged into master.
    branch = "harpoon2",
    event = "VeryLazy",
    keys = function()
      local harpoon = require "harpoon"

      return {
        {
          "<leader>ha",
          function()
            harpoon:list():append()
          end,
          desc = "[A]ppend file to Harpoon list",
        },
        {
          "<leader>ht",
          function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "[T]oggle Harpoon quick menu",
        },
        {
          "<leader>hh",
          function()
            harpoon:list():select(1)
          end,
          desc = "Switch to the first marked Harpoon file",
        },
        {
          "<leader>hj",
          function()
            harpoon:list():select(2)
          end,
          desc = "Switch to the second marked Harpoon file",
        },
        {
          "<leader>hk",
          function()
            harpoon:list():select(3)
          end,
          desc = "Switch to the third marked Harpoon file",
        },
        {
          "<leader>hl",
          function()
            harpoon:list():select(4)
          end,
          desc = "Switch to the fourth marked Harpoon file",
        },
      }
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
  -- {
  --   "nvim-pack/nvim-spectre",
  --   enabled = false,
  -- },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        prompt_prefix = "> ",
        selection_caret = "> ",
      },
    },
  },
  {
    "RRethy/vim-illuminate",
    enabled = false,
  },
}
