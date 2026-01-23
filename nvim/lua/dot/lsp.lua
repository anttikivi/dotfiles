local util = require("dot.util")

local M = {}

---@class dot.lsp.Config : vim.lsp.ClientConfig

---@type table<string, dot.lsp.Config>
local servers = {}

function M.setup() end

M.get_server_names = util.memoize(function()
    return util.keys(servers)
end)

---@param name string
---@param server dot.lsp.Config
function M.register_server(name, server)
    local found = false

    for k in pairs(servers) do
        if k == name then
            found = true
            break
        end
    end

    if not found then
        servers[name] = server
    end
end

return M
