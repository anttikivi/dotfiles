local config = require("config")
local util = require("util")

local M = {}

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

function M.setup()
    require("conform").setup({
        default_format_opts = {
            timeout_ms = config.formatting_timeout_ms,
            async = false,
            quiet = false,
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            lua = { "stylua" },
        },
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
end

return M
