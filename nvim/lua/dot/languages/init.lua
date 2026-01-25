local M = {}

---@class dot.Language.Linters
---@field [integer] string
---@field [string] dot.Linter

---@class dot.languages.Formatters
---@field [integer] string
---@field [string] dot.ConformFormatter

---@class dot.Language
---@field ensure_installed string[]?
---@field skip_install string[]? Names of linters and formatters that should not be automatically added to `ensure_installed`.
---@field filetypes (string | string[])? Optional file types to register the linters and formatters for. If not provided, the name of the language will be used.
---@field formatters dot.languages.Formatters?
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

    for _, lang in pairs(languages) do
        if type(lang.linters) == "table" then
            for k, linter in pairs(lang.linters) do
                local name = type(k) == "number" and linter or k

                local skip = false
                if type(lang.skip_install) == "table" then
                    for _, tool in ipairs(lang.skip_install) do
                        if name == tool then
                            skip = true
                        end
                    end
                end

                if not skip then
                    if type(lang.ensure_installed) == "nil" then
                        lang.ensure_installed = {}
                    end

                    local found = false
                    for _, tool in ipairs(lang.ensure_installed) do
                        if name == tool then
                            found = true
                        end
                    end

                    if not found then
                        lang.ensure_installed[#lang.ensure_installed + 1] = name
                    end
                end
            end
        end
    end

    local format = require("dot.format")
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

        if lang.formatters ~= nil then
            format.register_language(name, lang)
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
