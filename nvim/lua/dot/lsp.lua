local M = {}

---@return string[]
local function _get_server_names()
    local ret = {}
    for name, type in vim.fs.dir(vim.fn.stdpath("config") .. "/lsp") do
        if type == "file" and name:sub(-4) == ".lua" then
            ret[#ret + 1] = name:gsub("%.lua$", "")
        end
    end

    return ret
end

M.get_server_names = require("dot.util").memoize(_get_server_names)

function M.setup() end

return M
