-- This file has a stupid name to avoid conflicts with nvim-cmp.

local config = require("config")
local util = require("util")

local M = {}

-- This is a better implementation of `cmp.confirm`:
--  * check if the completion menu is visible without waiting for running sources
--  * create an undo point before confirming
-- This function is both faster and more reliable.
---@param opts? { select: boolean, behavior: cmp.ConfirmBehavior }
local function confirm(opts)
    local cmp = require("cmp")
    opts = vim.tbl_extend("force", {
        select = true,
        behavior = cmp.ConfirmBehavior.Insert,
    }, opts or {})
    return function(fallback)
        if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
            util.create_undo()
            if cmp.confirm(opts) then
                return
            end
        end
        return fallback()
    end
end

---@alias Placeholder { n: number, text: string }

---@param snippet string
---@param fn fun(placeholder: Placeholder): string
---@return string
local function snippet_replace(snippet, fn)
    return snippet:gsub("%$%b{}", function(m)
        local n, name = m:match("^%${(%d+):(.+)}$")
        return n and fn({ n = n, text = name }) or m
    end) or snippet
end

-- This function resolves nested placeholders in a snippet.
---@param snippet string
---@return string
local function snippet_preview(snippet)
    local ok, parsed = pcall(function()
        return vim.lsp._snippet_grammar.parse(snippet)
    end)
    return ok and tostring(parsed)
        or snippet_replace(snippet, function(placeholder)
            return snippet_preview(placeholder.text)
        end):gsub("%$0", "")
end

-- This function replaces nested placeholders in a snippet with LSP placeholders.
local function snippet_fix(snippet)
    local texts = {} ---@type table<number, string>
    return snippet_replace(snippet, function(placeholder)
        texts[placeholder.n] = texts[placeholder.n] or snippet_preview(placeholder.text)
        return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
    end)
end

local function expand(snippet)
    -- Native sessions don't support nested snippet sessions.
    -- Always use the top-level session.
    -- Otherwise, when on the first placeholder and selecting a new completion,
    -- the nested session will be used instead of the top-level session.
    -- See: https://github.com/LazyVim/LazyVim/issues/3199
    local session = vim.snippet.active() and vim.snippet._session or nil

    local ok, err = pcall(vim.snippet.expand, snippet)
    if not ok then
        local fixed = snippet_fix(snippet)
        ok = pcall(vim.snippet.expand, fixed)

        local msg = ok and "Failed to parse snippet,\nbut was able to fix it automatically."
            or ("Failed to parse snippet.\n" .. err)

        vim.notify(
            ([[%s
```%s
%s
```]]):format(msg, vim.bo.filetype, snippet),
            ok and vim.log.levels.WARN or vim.log.levels.ERROR
        )
    end

    -- Restore top-level session when needed
    if session then
        vim.snippet._session = session
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
            snippets = {
                expand = function(snippet)
                    return expand(snippet)
                end,
            },
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
                    return expand(args.body)
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
                ["<C-y>"] = confirm({ select = true }),
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

        for _, source in ipairs(opts.sources) do
            source.group_index = source.group_index or 1
        end

        local parse = require("cmp.utils.snippet").parse
        ---@diagnostic disable-next-line: duplicate-set-field
        require("cmp.utils.snippet").parse = function(input)
            local ok, ret = pcall(parse, input)
            if ok then
                return ret
            end
            return snippet_preview(input)
        end

        cmp.setup(opts)

        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        vim.lsp.config("*", {
            capabilities = capabilities,
        })
    end
end

return M
