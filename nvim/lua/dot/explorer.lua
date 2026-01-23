local config = require("dot.config")

local M = {}

function M.setup()
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
end

function M.pack_specs()
    local ret = {}

    if config.file_explorer == "oil" then
        ret[#ret + 1] = { src = "https://github.com/stevearc/oil.nvim", version = vim.version.range("2.15.0") }
    end

    return ret
end

return M
