local lsp_util = require("util.lsp")
local mason_registry = require("mason-registry")

local ensure_installed = {
    "prettier",
    "selene",
    "stylua",
}

local M = {}

function M.init()
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
                                    ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog")
                                    :format(
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

    vim.lsp.enable(require("util.lsp").server_names())

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
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, buffer, {autotrigger = true})
        end
    end)
    lsp_util.on_attach(function(client, buffer)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
    end)
end

return M
