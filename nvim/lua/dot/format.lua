local config = require("dot.config")
local util = require("dot.util")

local M = {}

---@class dot.Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

---@class dot.ConformFormatter : conform.FormatterConfigOverride

---@type boolean
vim.g.autoformat = config.autoformat

-- The top-level formatter definitions that are used in our own configuration.
-- This contains "conform" as one of the formatters.
---@type dot.Formatter[]
local formatters = {}

-- Formatters by filetype to be passed into Conform.
---@type table<string, string[]>
local formatters_by_ft = {}

-- Formatters that will be passed into conform.
---@type table<string, dot.ConformFormatter | fun(bufnr: integer): dot.ConformFormatter?>
local conform_formatters = {}

---@param buf number?
local function enabled(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local gaf = vim.g.autoformat
    local baf = vim.b[buf].autoformat

    if baf ~= nil then
        return baf
    end

    return gaf == nil or gaf
end

---@param buf number?
---@return (dot.Formatter | { active: boolean, resolved: string[] })[]
local function resolve(buf)
    local have_primary = false
    buf = buf or vim.api.nvim_get_current_buf()

    ---@param formatter dot.Formatter
    return vim.tbl_map(function(formatter)
        local sources = formatter.sources(buf)
        local active = #sources > 0 and (not formatter.primary or not have_primary)
        have_primary = have_primary or (active and formatter.primary) or false

        return setmetatable({
            active = active,
            resolved = sources,
        }, { __index = formatter })
    end, formatters)
end

---@param opts { force: boolean?, buf: number? }?
local function format(opts)
    opts = opts or {}

    local buf = opts.buf or vim.api.nvim_get_current_buf()

    if not ((opts and opts.force) or enabled(buf)) then
        return
    end

    local done = false

    for _, formatter in ipairs(resolve(buf)) do
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

---@param buf number?
local function info(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local gaf = vim.g.autoformat == nil or vim.g.autoformat
    local baf = vim.b[buf].autoformat
    local lines = {
        "# Status",
        ("- [%s] global **%s**"):format(gaf and "x" or " ", gaf and "enabled" or "disabled"),
        ("- [%s] buffer **%s**"):format(
            enabled(buf) and "x" or " ",
            baf == nil and "inherit" or baf and "enabled" or "disabled"
        ),
    }
    local have = false

    for _, formatter in ipairs(resolve(buf)) do
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

    vim.notify(table.concat(lines, "\n"), enabled(buf) and vim.log.levels.INFO or vim.log.levels.WARN)
end

function M.setup()
    local conform = require("conform")

    conform.setup({
        default_format_opts = {
            timeout_ms = config.formatting_timeout_ms,
            async = false,
            quiet = false,
            lsp_format = "fallback",
        },
        formatters_by_ft = formatters_by_ft,
        formatters = conform_formatters,
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

    vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("formatting", {}),
        callback = function(event)
            format({ buf = event.buf })
        end,
    })
    vim.api.nvim_create_user_command("Format", function()
        format({ force = true })
    end, { desc = "Format selection or buffer" })
    vim.api.nvim_create_user_command("FormatInfo", function()
        info()
    end, { desc = "Show info about the formatters for the current buffer" })
end

---@param formatter dot.Formatter
function M.register(formatter)
    formatters[#formatters + 1] = formatter

    table.sort(formatters, function(a, b)
        return a.priority > b.priority
    end)
end

---@param name string
---@param lang dot.Language
function M.register_language(name, lang)
    ---@type string[]
    local filetypes = {}
    if type(lang.filetypes) == "string" then
        filetypes[#filetypes + 1] = lang.filetypes --[[@as string]]
    elseif type(lang.filetypes) == "table" then
        vim.list_extend(filetypes, lang.filetypes --[=[@as string[]]=])
    else
        filetypes[#filetypes + 1] = name
    end

    for _, ft in ipairs(filetypes) do
        local ft_formatters = formatters_by_ft[ft] or {}
        if type(lang.formatters) == "table" then
            for k, formatter in pairs(lang.formatters) do
                if type(k) == "number" then
                    ft_formatters[#ft_formatters + 1] = formatter
                elseif type(k) == "string" then
                    ft_formatters[#ft_formatters + 1] = k
                    if type(conform_formatters[k]) == "function" then
                        vim.notify(
                            string.format(
                                '[format] cannot override conform.nvim formatter "%s" defined as a function',
                                k
                            ),
                            vim.log.levels.ERROR
                        )
                    else
                        if type(formatter) == "function" then
                            conform_formatters[k] = formatter
                        else
                            conform_formatters[k] = vim.tbl_deep_extend(
                                "force",
                                conform_formatters[k] --[[@as dot.ConformFormatter]]
                                    or {},
                                formatter
                            )
                        end
                    end
                end
            end
        end
        formatters_by_ft[ft] = ft_formatters
    end
end

function M.pack_specs()
    return {
        { src = "https://github.com/stevearc/conform.nvim", version = vim.version.range("9.1.0") },
    }
end

return M
