local config = require("dot.config")
local util = require("dot.util")

local M = {}

---@class dot.lsp.Config : vim.lsp.ClientConfig

---@type table<string, dot.lsp.Config>
local servers = {}

-- Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param fn fun(client: vim.lsp.Client, buf: integer)
---@param name? string
local function on_attach(fn, name)
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

function M.setup()
    for name, server in pairs(servers) do
        vim.lsp.config(name, server)
    end

    vim.lsp.enable(M.get_server_names())

    on_attach(function(_, buffer)
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
    on_attach(function(client, buffer)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
    end)

    vim.diagnostic.config({
        signs = {
            text = config.enable_icons and {
                [vim.diagnostic.severity.ERROR] = config.icons.diagnostics.error,
                [vim.diagnostic.severity.WARN] = config.icons.diagnostics.warn,
                [vim.diagnostic.severity.INFO] = config.icons.diagnostics.info,
                [vim.diagnostic.severity.HINT] = config.icons.diagnostics.hint,
            } or {
                [vim.diagnostic.severity.ERROR] = "E",
                [vim.diagnostic.severity.WARN] = "W",
                [vim.diagnostic.severity.INFO] = "I",
                [vim.diagnostic.severity.HINT] = "H",
            },
        },
        virtual_text = true,
    })

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
