local config = require("config")
local util = require("util")

local M = {}

---@module "conform"

---@class Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

---@type boolean
vim.g.autoformat = config.autoformat

---@param buf? number
function M.enabled(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local gaf = vim.g.autoformat
    local baf = vim.b[buf].autoformat

    if baf ~= nil then
        return baf
    end

    return gaf == nil or gaf
end

---@param opts? { force?: boolean, buf?: number }
function M.format(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()

    if not ((opts and opts.force) or M.enabled(buf)) then
        return
    end

    local done = false

    for _, formatter in ipairs(M.resolve(buf)) do
        if formatter.active then
            done = true
            util.try(function()
                return formatter.format(buf)
            end, { msg = "Formatter `" .. formatter.name .. "` failed" })
        end
    end

    if not done and opts and opts.force then
        vim.notify("No formatter available", vim.log.levels.WARN)
    end
end

function M.formatexpr()
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

    return vim.lsp.formatexpr({ timeout_ms = config.formatting_timeout_ms })
end

---@param buf? number
function M.info(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local gaf = vim.g.autoformat == nil or vim.g.autoformat
    local baf = vim.b[buf].autoformat
    local enabled = M.enabled(buf)
    local lines = {
        "# Status",
        ("- [%s] global **%s**"):format(gaf and "x" or " ", gaf and "enabled" or "disabled"),
        ("- [%s] buffer **%s**"):format(
            enabled and "x" or " ",
            baf == nil and "inherit" or baf and "enabled" or "disabled"
        ),
    }
    local have = false

    for _, formatter in ipairs(M.resolve(buf)) do
        if #formatter.resolved > 0 then
            have = true
            lines[#lines + 1] = "\n# " .. formatter.name .. (formatter.active and " ***(active)***" or "")
            for _, line in ipairs(formatter.resolved) do
                lines[#lines + 1] = ("- [%s] **%s**"):format(formatter.active and "x" or " ", line)
            end
        end
    end

    if not have then
        lines[#lines + 1] = "\n***No formatters available for this buffer.***"
    end

    vim.notify(table.concat(lines, "\n"), enabled and vim.log.levels.INFO or vim.log.levels.WARN)
end

M.formatters = {} ---@type Formatter[]

---@param formatter Formatter
function M.register(formatter)
    M.formatters[#M.formatters + 1] = formatter

    table.sort(M.formatters, function(a, b)
        return a.priority > b.priority
    end)
end

---@param buf? number
---@return (Formatter | { active: boolean, resolved: string[] })[]
function M.resolve(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local have_primary = false

    ---@param formatter Formatter
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

local prettier_supported = {
    "astro",
    "css",
    "graphql",
    "handlebars",
    "html",
    "javascript",
    "javascriptreact",
    "jinja",
    "json",
    "jsonc",
    "less",
    "markdown",
    "markdown.mdx",
    "nginx",
    "scss",
    "typescript",
    "typescriptreact",
    "vue",
    -- "xml",
    "yaml",
    "yaml.ansible",
}

---@alias ConformCtx {buf: number, filename: string, dirname: string}

--- Checks if a Prettier config file exists for the given context
---@param ctx ConformCtx
local function has_prettier_config(ctx)
    vim.fn.system({ "prettier", "--find-config-path", ctx.filename })

    return vim.v.shell_error == 0
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
---@param ctx ConformCtx
local function has_prettier_parser(ctx)
    local ft = vim.bo[ctx.buf].filetype --[[@as string]]
    if vim.tbl_contains(prettier_supported, ft) then
        return true
    end

    local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })

    ---@type boolean, string?
    local ok, parser = pcall(function()
        return vim.fn.json_decode(ret).inferredParser
    end)

    return ok and parser and parser ~= vim.NIL
end

has_prettier_config = require("util").memoize(has_prettier_config)
has_prettier_parser = require("util").memoize(has_prettier_parser)

function M.setup()
    local formatters_by_ft = {
        alloy = { "alloy" },
        bash = { "shfmt" },
        blade = { "blade-formatter" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        go = { "goimports", "gofumpt" },
        lua = { "stylua" },
        -- php = { "pint", "php_cs_fixer" },
        php = { "pint" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        shtml = { "superhtml" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        zig = { "zigfmt" },
        ziggy = { "ziggy" },
        ziggy_schema = { "ziggy_schema" },
    }
    local formatters = {
        injected = { options = { ignore_errors = true } },
        alloy = {
            command = "alloy",
            args = { "fmt" },
            condition = function(_, ctx)
                return vim.bo[ctx.buf].filetype == "alloy"
            end,
        },
        prettier = {
            condition = function(_, ctx)
                return has_prettier_parser(ctx) and (config.prettier_needs_config ~= true or has_prettier_config(ctx))
            end,
            prepend_args = function(_, ctx)
                if not has_prettier_config(ctx) then
                    local ft = vim.bo[ctx.buf].filetype --[[@as string]]

                    if ft == "yaml" then
                        return { "--print-width", "120" }
                    end

                    return { "--tab-width", "4", "--prose-wrap", "always", "--print-width", "80" }
                end

                return {}
            end,
        },
    }

    for _, ft in ipairs(prettier_supported) do
        formatters_by_ft[ft] = formatters_by_ft[ft] or {}
        table.insert(formatters_by_ft[ft], "prettier")
    end

    require("conform").setup({
        default_format_opts = {
            timeout_ms = config.formatting_timeout_ms,
            async = false,
            quiet = false,
            lsp_format = "fallback",
        },
        formatters_by_ft = formatters_by_ft,
        formatters = formatters,
    })

    M.register({
        name = "conform.nvim",
        priority = 100,
        primary = true,
        format = function(buf)
            require("conform").format({ bufnr = buf })
        end,
        sources = function(buf)
            local ret = require("conform").list_formatters(buf)
            ---@param v conform.FormatterInfo
            return vim.tbl_map(function(v)
                return v.name
            end, ret)
        end,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("formatting", {}),
        callback = function(event)
            M.format({ buf = event.buf })
        end,
    })
    vim.api.nvim_create_user_command("Format", function()
        M.format({ force = true })
    end, { desc = "Format selection or buffer" })
    vim.api.nvim_create_user_command("FormatInfo", function()
        M.info()
    end, { desc = "Show info about the formatters for the current buffer" })
end

return M
