local formatter = require("anttikivi.formatter")

local M = {}

---@class anttikivi.lsp.Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

---@type string[]
M.servers = {
    "ansiblels",
    "astro",
    "clangd",
    "gopls",
    "lua_ls",
    "vimls",
    "zls",
}

---@param filter? anttikivi.lsp.Filter
---@return vim.lsp.Client[]
function M.get_lsp_clients(filter)
    local clients = vim.lsp.get_clients(filter)
    return filter and filter.filter and vim.tbl_filter(filter.filter, clients) or clients
end

---Register a function to be run with an autocommand when a language server
---attaches to a buffer.
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

function M.init()
    vim.lsp.enable(M.servers)

    M.on_attach(function(_, buf)
        -- "gra": vim.lsp.buf.code_action()
        -- "gri": vim.lsp.buf.implementation()
        -- "grn": vim.lsp.buf.rename()
        -- "grr": vim.lsp.buf.references()
        -- "grt": vim.lsp.buf.type_definition()
        -- "grx": vim.lsp.codelens.run()
        -- "gO": vim.lsp.buf.document_symbol()
        -- CTRL-S: vim.lsp.buf.signature_help()
        vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = buf })
        vim.keymap.set("n", "gra", FzfLua.lsp_code_actions, { buffer = buf })
    end)

    M.on_attach(function(client, buf)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        end
    end)

    M.on_attach(function(client, buffer)
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
        end
    end)

    formatter.register({
        name = "LSP",
        primary = true,
        priority = 1,
        format = function(buf)
            vim.lsp.buf.format({ timeout_ms = formatter.formatting_timeout_ms, bufnr = buf })
        end,
        sources = function(buf)
            local clients = M.get_lsp_clients({ bufnr = buf })
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

    require("lazydev").setup({
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    })
end

return M
