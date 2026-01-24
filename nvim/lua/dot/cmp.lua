local config = require("dot.config")
local util = require("dot.util")

local M = {}

-- This is a better implementation of `cmp.confirm`:
--  * check if the completion menu is visible without waiting for running sources
--  * create an undo point before confirming
-- This function is both faster and more reliable.
---@param opts? { select: boolean, behavior: cmp.ConfirmBehavior }
local function cmp_confirm(opts)
    local cmp = require("cmp")
    opts = vim.tbl_extend("force", {
        select = true,
        behavior = cmp.ConfirmBehavior.Insert,
    }, opts or {})
    return function(fallback)
        if cmp.visible() then
            util.create_undo()
            if cmp.confirm(opts) then
                return
            end
        end
        return fallback()
    end
end

function M.setup()
    if config.cmp == "native" then
        require("dot.lsp").on_attach(function(client, buffer)
            if client:supports_method("textDocument/completion") then
                vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
            end
        end)
    elseif config.cmp == "nvim-cmp" then
        local cmp = require("cmp")
        local defaults = require("cmp.config.default")()

        local auto_select = true
        local keymap = {
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-y>"] = cmp_confirm({ select = true }),
        }

        local opts = {
            snippet = {
                expand = function(args)
                    return vim.snippet.expand(args.body)
                end,
            },
            completion = {
                completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
            },
            preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
            mapping = cmp.mapping.preset.insert(keymap),
            sources = cmp.config.sources({
                { name = "lazydev" },
                { name = "nvim_lsp" },
                { name = "path" },
            }, {
                { name = "buffer" },
            }),
            sorting = defaults.sorting,
        }

        cmp.setup(opts)

        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        vim.lsp.config("*", {
            capabilities = capabilities,
        })
    end
end

function M.pack_specs()
    local result = {}

    if config.cmp == "nvim-cmp" then
        result[#result + 1] = {
            src = "https://github.com/hrsh7th/nvim-cmp",
            version = "da88697d7f45d16852c6b2769dc52387d1ddc45f",
        }
        result[#result + 1] = {
            src = "https://github.com/hrsh7th/cmp-nvim-lsp",
            version = "cbc7b02bb99fae35cb42f514762b89b5126651ef",
        }
        result[#result + 1] = {
            src = "https://github.com/hrsh7th/cmp-buffer",
            version = "b74fab3656eea9de20a9b8116afa3cfc4ec09657",
        }
        result[#result + 1] = {
            src = "https://github.com/hrsh7th/cmp-path",
            version = "c642487086dbd9a93160e1679a1327be111cbc25",
        }
    end

    return result
end

return M
