---@class util.lsp
local M = {}

---@class util.lsp.Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

---@param filter? util.lsp.Filter
---@return vim.lsp.Client[]
function M.get_clients(filter)
    local clients = vim.lsp.get_clients(filter)
    return filter and filter.filter and vim.tbl_filter(filter.filter, clients) or clients
end

-- Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param fn fun(client: vim.lsp.Client, buf: integer)
---@param name? string
function M.on_attach(fn, name)
    return vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local buffer = args.buf ---@type integer
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and (not name or client.name == name) then
                fn(client, buffer)
            end
        end,
    })
end

---@return string[]
local function server_names()
    local ret = {}
    for name, type in vim.fs.dir(vim.fn.stdpath("config") .. "/lsp") do
        if type == "file" and name:sub(-4) == ".lua" then
            ret[#ret + 1] = name:gsub("%.lua$", "")
        end
    end

    return ret
end

M.server_names = require("util").memoize(server_names)

return M
