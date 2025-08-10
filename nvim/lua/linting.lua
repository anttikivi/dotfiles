local util = require("util")

local M = {}

local linters_by_ft = {
    bash = { "shellcheck", "bash" },
    c = { "clangtidy" },
    cpp = { "clangtidy" },
    lua = { "selene" },
    markdown = { "markdownlint-cli2" },
    php = { "phpcs" },
    sh = { "shellcheck" },
    terraform = { "terraform_validate", "tflint" },
    ["yaml.ansible"] = { "ansible_lint" },
}
---@type table<string, table>
local linters = {
    selene = {
        condition = function()
            local root = require("root").get({ normalize = true })
            if root ~= vim.uv.cwd() then
                return false
            end
            return vim.fs.find({ "selene.toml" }, { path = root, upward = true })[1]
        end,
    },
}

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

local function run_lint()
    local lint = require("lint")

    local names = lint._resolve_linter_by_ft(vim.bo.filetype)
    names = vim.list_extend({}, names)

    if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
    end

    vim.list_extend(names, lint.linters_by_ft["*"] or {})

    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    names = vim.tbl_filter(function(name)
        local linter = lint.linters[name]

        if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
        end

        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, names)

    if #names > 0 then
        lint.try_lint(names)
    end
end

function M.setup()
    local lint = require("lint")

    for name, linter in pairs(linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
            lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
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
        group = util.augroup("lint"),
        callback = debounce(100, run_lint),
    })
end

return M
