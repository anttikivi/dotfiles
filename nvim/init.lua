local cmps = require("cmps")
local colors = require("colors")
local config = require("config")
local picker = require("picker")

require("options")
require("autocmds")
require("keymaps")

local pack_specs = {
    { src = "https://github.com/folke/lazydev.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mfussenegger/nvim-lint" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
}
vim.list_extend(pack_specs, cmps.pack_spec())
vim.list_extend(pack_specs, colors.pack_spec())
vim.list_extend(pack_specs, picker.pack_spec())

vim.pack.add(pack_specs)

require("root").setup()
cmps.setup()
require("lsp").setup()
require("linting").setup()
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

picker.setup()

require("gitsigns").setup()

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

require("lazydev").setup({
    library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
})

colors.init()

if config.enable_statusline then
    require("statusline").setup()
end
