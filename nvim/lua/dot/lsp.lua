local M = {}

---@class dot.lsp.Config : vim.lsp.ClientConfig

---@type table<string, dot.lsp.Config>
M._servers = {}

---@param name string
---@param server dot.lsp.Config
function M.register_server(name, server)
    vim.notify(("register: %s"):format(name))
    local found = false

    for k in pairs(M._servers) do
        if k == name then
            found = true
            break
        end
    end

    if not found then
        M._servers[name] = server
    end
end

---@return string[]
local function _get_server_names()
    return require("dot.util").keys(M._servers)
end

M.get_server_names = require("dot.util").memoize(_get_server_names)

function M.setup() end

return M
