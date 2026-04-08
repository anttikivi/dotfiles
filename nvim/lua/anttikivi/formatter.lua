local ak = require("anttikivi")
local conform = require("conform")

local M = {}

---@class anttikivi.Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

---@class anttikivi.ConformFormatter : conform.FormatterConfigOverride

local prettier_require_config = true

---@type integer
M.formatting_timeout_ms = 3000

---@type anttikivi.Formatter[]
M.formatters = {}

---Check if a Prettier config exists in the given Conform context.
---@param ctx conform.Context
---@return boolean
local prettier_has_config = ak.memoize(function(ctx)
    vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
    return vim.v.shell_error == 0
end)

---@param buf number?
local function is_formatter_enabled(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local gaf = vim.g.autoformat
    local baf = vim.b[buf].autoformat

    if baf ~= nil then
        return baf
    end

    return gaf == nil or gaf
end

---@param buf number?
---@return (anttikivi.Formatter | { active: boolean, resolved: string[] })[]
local function resolve_formatter(buf)
    local have_primary = false
    buf = buf or vim.api.nvim_get_current_buf()

    ---@param formatter anttikivi.Formatter
    return vim.tbl_map(function(formatter)
        local sources = formatter.sources(buf)
        local active = #sources > 0 and (not formatter.primary or not have_primary)
        have_primary = have_primary or (active and formatter.primary) or false

        return setmetatable({
            active = active,
            resolved = sources,
        }, { __index = formatter })
    end, M.formatters)
end

---@param opts { force: boolean?, buf: number? }?
local function format(opts)
    opts = opts or {}

    local buf = opts.buf or vim.api.nvim_get_current_buf()

    if not ((opts and opts.force) or is_formatter_enabled(buf)) then
        return
    end

    local done = false

    for _, formatter in ipairs(resolve_formatter(buf)) do
        if formatter.active then
            done = true
            local ok, err = pcall(formatter.format, buf)
            if not ok then
                vim.schedule(function()
                    vim.notify(string.format("[formatter] %q failed: %s", formatter.name, err), vim.log.levels.ERROR)
                end)
            end
        end
    end

    if not done and opts and opts.force then
        vim.notify("[formatter] no formatter available", vim.log.levels.WARN)
    end
end

---Register a "top-level" formatter. These are things like the language server
---client and conform.nvim.
---@param formatter anttikivi.Formatter
function M.register(formatter)
    M.formatters[#M.formatters + 1] = formatter

    table.sort(M.formatters, function(a, b)
        return a.priority > b.priority
    end)
end

function M.init()
    conform.setup({
        default_format_opts = {
            timeout_ms = M.formatting_timeout_ms,
            async = false,
            quiet = false,
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            astro = { "prettier" },
            bash = { "shfmt" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            css = { "oxfmt", "prettier" },
            go = { "goimports", "gofumpt" },
            javascript = { "oxfmt", "prettier" },
            json = { "oxfmt", "prettier" },
            jsonc = { "oxfmt", "prettier" },
            lua = { "stylua" },
            markdown = { "oxfmt", "prettier" },
            opentofu = { "tofu_fmt" },
            ["opentofu-vars"] = { "tofu_fmt" },
            sh = { "shfmt" },
            toml = { "taplo" },
            typescript = { "oxfmt", "prettier" },
            yaml = { "oxfmt", "prettier" },
            ["yaml.ansible"] = { "oxfmt", "prettier" },
            zig = { "zigfmt" },
        },
        formatters = {
            oxfmt = {
                append_args = function(_, ctx)
                    local root = vim.fs.root(ctx.dirname, { ".oxfmtrc.json", ".oxfmtrc.jsonc" })
                    if not root then
                        return { "--config", vim.fs.abspath("~/src/personal/dotfiles/oxfmtrc.json") }
                    end

                    return {}
                end,
                condition = function(_, ctx)
                    return not prettier_has_config(ctx)
                end,
            },
            prettier = {
                condition = function(_, ctx)
                    return not prettier_require_config or prettier_has_config(ctx)
                end,
            },
        },
    })

    M.register({
        name = "conform.nvim",
        priority = 100,
        primary = true,
        format = function(buf)
            conform.format({ bufnr = buf })
        end,
        sources = function(buf)
            local result = conform.list_formatters(buf)
            ---@param v conform.FormatterInfo
            return vim.tbl_map(function(v)
                return v.name
            end, result)
        end,
    })

    vim.api.nvim_create_augroup("formatting", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = "formatting",
        callback = function(event)
            format({ buf = event.buf })
        end,
    })

    vim.api.nvim_create_user_command("Format", function()
        format({ force = true })
    end, { desc = "Format selection or buffer" })
    vim.api.nvim_create_user_command("Fmt", "Format", { desc = "Format selection of buffer" })

    vim.api.nvim_create_user_command("FormatInfo", function()
        local buf = vim.api.nvim_get_current_buf()
        local gaf = vim.g.autoformat
        local baf = vim.b[buf].autoformat
        local lines = {
            "# Status",
            string.format("- [%s] global **%s**", gaf and "x" or " ", gaf and "enabled" or "disabled"),
            string.format(
                "- [%s] buffer **%s**",
                is_formatter_enabled(buf) and "x" or " ",
                baf == nil and "inherit" or baf and "enabled" or "disabled"
            ),
        }
        local have = false

        for _, formatter in ipairs(resolve_formatter(buf)) do
            if #formatter.resolved > 0 then
                have = true
                lines[#lines + 1] = "\n# " .. formatter.name .. (formatter.active and " ***(active)***" or "")
                for _, line in ipairs(formatter.resolved) do
                    lines[#lines + 1] = string.format("- [%s] **%s**", formatter.active and "x" or " ", line)
                end
            end
        end

        if not have then
            lines[#lines + 1] = "\n***No formatters available for this buffer.***"
        end

        vim.notify(table.concat(lines, "\n"), is_formatter_enabled(buf) and vim.log.levels.INFO or vim.log.levels.WARN)
    end, { desc = "Show info about the formatters for the current buffer" })
end

function _G.formatexpr()
    local use_conform = false
    ---@type vim.pack.PlugData[]
    local plugins = vim.pack.get()
    for _, p in ipairs(plugins) do
        if p.spec.name == "conform.nvim" and p.active then
            use_conform = true
        end
    end

    if use_conform then
        return require("conform").formatexpr()
    end

    return vim.lsp.formatexpr({ timeout_ms = M.formatting_timeout_ms })
end

return M
