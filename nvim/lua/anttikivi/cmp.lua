local cmp = require("blink.cmp")

cmp.setup({
    completion = {
        documentation = {
            auto_show = true,
        },
    },
    keymap = {
        preset = "default",
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },
})
