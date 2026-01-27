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

return M
