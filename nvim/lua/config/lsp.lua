local config = require("dot.config")
local util = require("dot.util")

local M = {}

---@class dot.lsp.Config : vim.lsp.ClientConfig

---@class Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

---@type table<string, dot.lsp.Config>
local registered_servers = {}

function M.setup()
    for name, server in pairs(registered_servers) do
        vim.lsp.config(name, server)
    end

    vim.lsp.enable(M.get_server_names())

    require("dot.format").register({
        name = "LSP",
        primary = true,
        priority = 1,
        format = function(buf)
            vim.lsp.buf.format({ timeout_ms = config.formatting_timeout_ms, bufnr = buf })
        end,
        sources = function(buf)
            local clients = M.get_clients({ bufnr = buf })
            ---@param client vim.lsp.Client
            local ret = vim.tbl_filter(function(client)
                return client:supports_method("textDocument/formatting")
                    or client:supports_method("textDocument/rangeFormatting")
            end, clients)
            ---@param client vim.lsp.Client
            return vim.tbl_map(function(client)
                return client.name
            end, ret)
        end,
    })

    M.on_attach(function(_, buffer)
        -- Neovim now provides some default mappings so I don't need to add my
        -- own:
        -- "grn": vim.lsp.buf.rename()
        -- "gra": vim.lsp.buf.code_action()
        -- "grr": vim.lsp.buf.references()
        -- "gri": vim.lsp.buf.implementation()
        -- "grt": vim.lsp.buf.type_definition()
        -- "gO": vim.lsp.buf.document_symbol()
        -- CTRL-S: vim.lsp.buf.signature_help()
        vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = buffer })
    end)
    M.on_attach(function(client, buffer)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
    end)

    require("lazydev").setup({
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    })
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

---@param filter? Filter
---@return vim.lsp.Client[]
function M.get_clients(filter)
    local clients = vim.lsp.get_clients(filter)
    return filter and filter.filter and vim.tbl_filter(filter.filter, clients) or clients
end

M.get_server_names = util.memoize(function()
    return util.keys(registered_servers)
end)

---Register the given servers to the LSP config.
---@param servers table<string, dot.lsp.Config>
function M.register_servers(servers)
    for key, value in pairs(servers) do
        registered_servers[key] = vim.tbl_deep_extend("force", registered_servers[key] or {}, value)
    end
end

return M
