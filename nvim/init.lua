local config = require("config")

require("options")
require("keymaps")

require("pack").setup()

require("lsp").setup()

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
