local colors = require("colors")
local config = require("config")

require("config.options")
require("config.autocmds")
require("config.keymaps")

vim.pack.add({
    colors.colorscheme_plugin_spec(),
    { src = "https://github.com/f-person/auto-dark-mode.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-telescope/telescope.nvim" },
    { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
})

require("lsp").setup()
require("treesitter")
require("formatting").setup()

if config.file_explorer == "oil" then
    require("oil").setup({
        default_file_explorer = true,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 2000,
        },
        watch_for_changes = true,
        view_options = {
            show_hidden = true,
            is_always_hidden = function(name)
                return name == ".." or name == ".DS_Store"
            end,
        },
    })
end

local actions = require("telescope.actions")
require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<esc>"] = actions.close,
            },
        },
    },
})
if not pcall(require("telescope").load_extension, "fzf") then
    vim.notify("Failed to load fzf extension for telescope", vim.log.levels.WARN)
end

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

local harpoon = require("harpoon")
harpoon:setup({
    settings = {
        save_on_toggle = true,
    },
})
vim.keymap.set("n", "<C-h>", function()
    harpoon:list():add()
end)
vim.keymap.set("n", "<leader>h", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
end)
local ordinal = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth" }
for i, v in ipairs(ordinal) do
    vim.keymap.set("n", "<leader>" .. i, function()
        harpoon:list():select(i)
    end, { desc = string.format("Switch to the %s harpooned file", v) })
end

colors.init()
