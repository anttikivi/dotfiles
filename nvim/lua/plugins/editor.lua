return {
  {
    "lewis6991/gitsigns.nvim",
    version = "^1.0.2",
    event = "LazyFile",
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
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
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
  },
  {
    "stevearc/oil.nvim",
    version = "^2.15.0",
    enabled = vim.g.file_explorer == "oil" or vim.g.file_explorer == "oil.nvim",
    lazy = false,
    ---@module "oil"
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      columns = {
        "icon",
        -- "permissions",
        -- "size",
      },
      lsp_file_methods = {
        enabled = true,
        timeout_ms = 2000,
      },
      watch_for_changes = true,
      keymaps = {
        ["<CR>"] = "actions.select",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
      },
      -- TODO: Review the default keymaps.
      use_default_keymaps = false,
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          return name == ".." or name == ".DS_Store" or name == ".git"
        end,
      },
    },
    keys = {
      { "-", "<cmd>Oil<CR>", mode = { "n" }, desc = "Open parent directory" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    version = false, -- TODO: Tag 0.1.8 is too old.
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
      local telescopeConfig = require("telescope.config")

      -- Clone the default config.
      local vimgrep_arguments =
        { unpack(telescopeConfig.values.vimgrep_arguments) }

      -- Search in hidden files but exclude '.git' directory.
      table.insert(vimgrep_arguments, "--hidden")
      table.insert(vimgrep_arguments, "--glob")
      table.insert(vimgrep_arguments, "!**/.git/*")

      return {
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = actions.close,
            },
          },
          vimgrep_arguments = vimgrep_arguments,
        },
        extensions = {
          ["ui-select"] = require("telescope.themes").get_dropdown(),
        },
        pickers = {
          find_files = {
            -- Search in hidden files but exclude '.git'.
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!**/.git/*",
            },
          },
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
    version = "^1.4.0",
    event = "LazyFile",
    cmd = { "TodoTrouble", "TodoTelescope" },
    opts = {},
  },
}
