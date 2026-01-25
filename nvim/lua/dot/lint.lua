local util = require("dot.util")

local M = {}

---@class dot.Linter : lint.Linter
---@field name string?
---@field cmd string?
---@field parser (lint.Parser | lint.parse)?
---@field condition function?
---@field prepend_args? (string|fun():string)[]

---@type table<string, string[]>
local linters_by_ft = {}

---@type table<string, dot.Linter>
local registered_linters = {}

local function debounce(ms, fn)
    local timer = vim.uv.new_timer()

    return function(...)
        local argv = { ... }

        if timer == nil then
            vim.notify("Error running `debounce`, timer is nil", vim.log.levels.ERROR)
            return
        end

        timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
        end)
    end
end

local function try_lint()
    local lint = require("lint")

    local names = lint._resolve_linter_by_ft(vim.bo.filetype)

    if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
    end
    vim.list_extend(names, lint.linters_by_ft["*"] or {})

    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    names = vim.tbl_filter(function(name)
        local linter = lint.linters[name] --[[@as dot.Linter]]
        if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
        end

        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, names)

    if #names > 0 then
        lint.try_lint(names, { cwd = require("dot.root").get() })
    end
end

function M.setup()
    local lint = require("lint")

    for name, linter in pairs(registered_linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
            lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] --[[@as table]], linter)
            if type(linter.prepend_args) == "table" then
                lint.linters[name].args = lint.linters[name].args or {}

                vim.list_extend(lint.linters[name].args, linter.prepend_args)
            end
        else
            lint.linters[name] = linter
        end
    end

    lint.linters_by_ft = linters_by_ft

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = debounce(100, try_lint),
    })
end

---Registers given linter tools for the given filetypes.
---@param filetypes string[]
---@param linters string[]
function M.register_filetypes(filetypes, linters)
    for _, ft in ipairs(filetypes) do
        local registered = linters_by_ft[ft] or {}
        for _, linter in ipairs(linters) do
            if not util.contains(linters_by_ft, linter) then
                registered[#registered + 1] = linter
            end
        end
        linters_by_ft[ft] = registered
    end
end

---@param linters table<string, dot.Linter>
function M.register_linters(linters)
    for key, value in pairs(linters) do
        registered_linters[key] = vim.tbl_deep_extend("force", registered_linters[key] or {}, value)
    end
end

function M.pack_specs()
    return {
        { src = "https://github.com/anttikivi/nvim-lint", version = "386ca59429b0b033c45cff8efc0902445a1d6173" },
    }
end

return M
