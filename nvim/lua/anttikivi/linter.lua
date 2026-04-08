local ak = require("anttikivi")
local root = require("anttikivi.root")
local lint = require("lint")

---@class anttikivi.Linter : lint.Linter
---@field name string?
---@field cmd string?
---@field parser (lint.Parser | lint.parse)?
---@field condition function?
---@field prepend_args? (string|fun():string)[]

---@type table<string, anttikivi.Linter>
local linters = {
    selene = {
        args = {
            "--config",
            vim.fs.find({ "selene.toml" }, { path = root.get({ normalize = true }), upward = true })[1],
            "--display-style",
            "json",
            "-",
        },
        condition = function()
            return vim.fs.find({ "selene.toml" }, { path = root.get({ normalize = true }), upward = true })[1]
        end,
    },
}

for name, linter in pairs(linters) do
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

lint.linters_by_ft = {
    c = { "clangtidy" },
    cpp = { "clangtidy" },
    go = { "golangcilint" },
    javascript = { "oxlint" },
    lua = { "selene" },
    opentofu = { "tofu" },
    ["opentofu-vars"] = { "tofu" },
    typescript = { "oxlint" },
    yaml = { "yamllint" },
    ["yaml.ansible"] = { "ansible_lint" },
}

local function try_lint()
    local names = lint._resolve_linter_by_ft(vim.bo.filetype)

    if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
    end
    vim.list_extend(names, lint.linters_by_ft["*"] or {})

    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    names = vim.tbl_filter(function(name)
        local linter = lint.linters[name] --[[@as anttikivi.Linter]]
        if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
        end

        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, names)

    if #names > 0 then
        lint.try_lint(names)
    end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = ak.debounce(100, try_lint),
})
