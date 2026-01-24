local M = {}

---@class dot.Language.Linters
---@field [integer] string
---@field [string] dot.Linter

---@class dot.Language
---@field ensure_installed string[]?
---@field filetypes (string | string[])? Optional file types to register the linters and formatters for. If not provided, the name of the language will be used.
---@field formatters string[]?
---@field linters dot.Language.Linters?
---@field servers table<string, dot.lsp.Config>?
---@field treesitter (string | string[])? Tree-sitter parsers for the language.

---@type table<string, dot.Language>
local languages = {}

function M.setup()
    local path = vim.fn.stdpath("config") .. "/lua/dot/languages/"
    local files = vim.fn.globpath(path, "*.lua", false, true)

    table.sort(files)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        if name ~= "init" then
            local module_name = "dot.languages." .. name
            local ok, module = pcall(require, module_name)
            if ok then
                languages[name] = module
            else
                vim.notify(("[languages] failed to load %s: %s"):format(module_name, module), vim.log.levels.ERROR)
            end
        end
    end

    local mason = require("dot.mason")
    local lint = require("dot.lint")
    local lsp = require("dot.lsp")
    local treesitter = require("dot.treesitter")

    for name, lang in pairs(languages) do
        if lang.ensure_installed ~= nil then
            for _, pkg in ipairs(lang.ensure_installed) do
                mason.ensure_installed(pkg)
            end
        end

        if lang.linters ~= nil then
            lint.register_language(name, lang)
        end

        if lang.servers ~= nil then
            for server_name, server in pairs(lang.servers) do
                lsp.register_server(server_name, server)
            end
        end

        treesitter.register_language(name, lang)
    end
end

return M
