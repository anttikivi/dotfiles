-- This file has a stupid name to avoid conflicts with nvim-cmp.

local config = require("config")
local util = require("util")

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

function M.pack_spec()
    if config.cmp == "native" then
        return {}
    elseif config.cmp == "blink" then
        return {
            { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1.6.0") },
        }
    elseif config.cmp == "nvim-cmp" then
        return {
            { src = "https://github.com/hrsh7th/nvim-cmp" },
            { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
            { src = "https://github.com/hrsh7th/cmp-buffer" },
            { src = "https://github.com/hrsh7th/cmp-path" },
        }
    end

    vim.notify(("Invalid value for `config.cmp`: %q"):format(config.cmp), vim.log.levels.ERROR)

    return {}
end

function M.setup()
    if config.cmp == "native" then
        require("lsp").on_attach(function(client, buffer)
            if client:supports_method("textDocument/completion") then
                vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
            end
        end)
    elseif config.cmp == "blink" then
        local blink = require("blink.cmp")
        blink.setup({
            completion = {
                accept = {
                    -- experimental auto-brackets support
                    auto_brackets = {
                        enabled = false,
                    },
                },
                menu = {
                    draw = {
                        treesitter = { "lsp" },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                },
                ghost_text = {
                    enabled = false,
                },
            },
            keymap = { preset = "default" },
            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100, -- show at a higher priority than lsp
                    },
                },
            },
            cmdline = {
                enabled = false,
            },
        })
    elseif config.cmp == "nvim-cmp" then
        local cmp = require("cmp")
        local defaults = require("cmp.config.default")()

        local auto_select = true
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
            mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-y>"] = cmp_confirm({ select = true }),
            }),
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

return M
