local config = require("config")
local lsp_util = require("util.lsp")
local mason_registry = require("mason-registry")

local M = {}

local ensure_installed = {
    "prettier",
    "selene",
    "stylua",
}

function M.setup()
    require("mason").setup()

    mason_registry:on("package:install:success", function()
        vim.defer_fn(function()
            vim.api.nvim_exec_autocmds("FileType", {
                buffer = vim.api.nvim_get_current_buf(),
            })
        end, 100)
    end)

    mason_registry.refresh(vim.schedule_wrap(function()
        if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
            require("util.mason").install_servers()

            for _, tool in ipairs(ensure_installed) do
                local pkg = mason_registry.get_package(tool)
                if not pkg:is_installed() and not pkg:is_installing() then
                    vim.notify(("[mason] installing %s"):format(tool))
                    pkg:install(
                        {},
                        vim.schedule_wrap(function(success)
                            if success then
                                vim.notify(("[mason] %s was successfully installed"):format(tool))
                            else
                                vim.notify(
                                    ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                                        tool
                                    ),
                                    vim.log.levels.ERROR
                                )
                            end
                        end)
                    )
                end
            end
        end
    end))

    vim.lsp.enable(lsp_util.server_names())

    require("formatting").register({
        name = "LSP",
        primary = true,
        priority = 1,
        format = function(buf)
            vim.lsp.buf.format({ timeout_ms = config.formatting_timeout_ms, bufnr = buf })
        end,
        sources = function(buf)
            local clients = lsp_util.get_clients({ bufnr = buf })
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

    lsp_util.on_attach(function(_, buffer)
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
    lsp_util.on_attach(function(client, buffer)
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
        end
    end)
    lsp_util.on_attach(function(client, buffer)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
    end)

    vim.diagnostic.config({
        virtual_text = true,
        -- virtual_lines = true
    })
end

return M
