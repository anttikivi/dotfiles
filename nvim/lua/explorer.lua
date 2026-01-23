local config = require("config")

local M = {}

function M.pack_specs()
    local ret = {}

    if config.file_explorer == "oil" then
        ret[#ret + 1] = { src = "https://github.com/stevearc/oil.nvim", version = vim.version.range("2.15.0") }
    end

    return ret
end

return M
