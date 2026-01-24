local M = {}

function M.setup()
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
end

function M.pack_specs()
    return {
        { src = "https://github.com/ThePrimeagen/harpoon", version = "87b1a3506211538f460786c23f98ec63ad9af4e5" },
    }
end

return M
