local util = require("dot.util")

local M = {}

---@class dot.lsp.Config : vim.lsp.ClientConfig

---@type table<string, dot.lsp.Config>
local servers = {}

function M.setup()
    for name, server in pairs(servers) do
        vim.lsp.config(name, server)
    end

    vim.lsp.enable(M.get_server_names())

    require("lazydev").setup({
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    })
end

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

function M.pack_specs()
    return {
        { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("1.10.0") },
    }
end

return M
