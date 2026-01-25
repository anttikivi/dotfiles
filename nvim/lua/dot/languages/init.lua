local util = require("dot.util")

local M = {}

---@class dot.languages.Linters
---@field [integer] string
---@field [string] dot.Linter

---@class dot.languages.Formatters
---@field [integer] string
---@field [string] dot.ConformFormatter | fun(bufnr: integer): dot.ConformFormatter?

---@class dot.languages.Config
---@field ensure_installed (string | string[])? Packages that should be installed by Mason in addition to the language servers, linters, and formatters.
---@field filetypes (string | string[])? Optional file types to register the linters and formatters for. If not provided, the name of the language will be used.
---@field formatters dot.languages.Formatters? Formatters for the language.
---@field linters dot.languages.Linters? Linters for the language.
---@field servers table<string, dot.lsp.Config>? Language servers for the language.
---@field skip_install string[]? Names of linters and formatters that should not be automatically installed.
---@field treesitter (string | string[])? Tree-sitter parsers for the language.

---@class (exact) dot.Language
---@field ensure_installed string[] All of the linters, formatters, and other packages to install on behalf of the language.
---@field filetypes string[]
---@field formatters table<string, dot.ConformFormatter | fun(bufnr: integer): dot.ConformFormatter?> All of the custom formatters for the language.
---@field formatters_for_fts string[] Names of all of the formatters to add for the language's file types.
---@field linters table<string, dot.Linter> All of the custom linters for the language.
---@field linters_for_fts string[] name of all of the linters to add for the language's file types.
---@field servers table<string, dot.lsp.Config> Language servers for the language.
---@field treesitter_parsers string[] Tree-sitter parsers for the language.

---@type table<string, dot.languages.Config>
local language_configs = {}

---@type dot.Language[]
local languages = {}

---@param name string
---@param config dot.languages.Config
---@return dot.Language
local function normalize(name, config)
    ---@type string[]
    local ensure_installed = {}
    if type(config.ensure_installed) == "string" then
        ensure_installed = {
            config.ensure_installed --[[@as string]],
        }
    elseif type(config.ensure_installed) == "table" then
        ensure_installed = config.ensure_installed --[=[@as string[]]=]
    elseif type(config.ensure_installed) ~= "nil" then
        vim.notify(
            string.format("[language] ensure_installed in %s is neither string nor table", name),
            vim.log.levels.ERROR
        )
    end

    ---@type string[]
    local filetypes = {}
    if type(config.filetypes) == "string" then
        filetypes = {
            config.filetypes --[[@as string]],
        }
    elseif type(config.filetypes) == "table" then
        filetypes = config.filetypes --[=[@as string[]]=]
    else
        filetypes = { name }
    end

    ---@type table<string, dot.ConformFormatter | fun(bufnr: integer): dot.ConformFormatter?>
    local formatters = {}

    ---@type string[]
    local formatters_for_fts = {}

    for key, value in pairs(config.formatters) do
        if type(key) == "number" then
            if not util.contains(formatters_for_fts, value) then
                formatters_for_fts[#formatters_for_fts + 1] = value
            end
        elseif type(key) == "string" then
            if not util.contains(formatters_for_fts, key) then
                formatters_for_fts[#formatters_for_fts + 1] = key
            end

            formatters[key] = value
        end
    end

    for _, value in ipairs(formatters_for_fts) do
        if not util.contains(ensure_installed, value) and not util.contains(config.skip_install, value) then
            ensure_installed[#ensure_installed + 1] = value
        end
    end

    ---@type table<string, dot.Linter>
    local linters = {}

    ---@type string[]
    local linters_for_fts = {}

    for key, value in pairs(config.linters) do
        if type(key) == "number" then
            if not util.contains(linters_for_fts, value) then
                linters_for_fts[#linters_for_fts + 1] = value
            end
        elseif type(key) == "string" then
            if not util.contains(linters_for_fts, key) then
                linters_for_fts[#linters_for_fts + 1] = key
            end

            linters[key] = value
        end
    end

    for _, value in ipairs(linters_for_fts) do
        if not util.contains(ensure_installed, value) and not util.contains(config.skip_install, value) then
            ensure_installed[#ensure_installed + 1] = value
        end
    end

    ---@type string[]
    local treesitter = {}
    if type(config.treesitter) == "string" then
        treesitter = {
            config.treesitter --[[@as string]],
        }
    elseif type(config.treesitter) == "table" then
        treesitter = config.treesitter --[=[@as string[]]=]
    else
        vim.notify(string.format("[language] treesitter in %s is neither string nor table", name), vim.log.levels.ERROR)
    end

    ---@type dot.Language
    return {
        ensure_installed = ensure_installed,
        filetypes = filetypes,
        formatters = formatters,
        formatters_for_fts = formatters_for_fts,
        linters = linters,
        linters_for_fts = linters_for_fts,
        servers = config.servers or {},
        treesitter_parsers = treesitter,
    }
end

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
                language_configs[name] = module
            else
                vim.notify(("[languages] failed to load %s: %s"):format(module_name, module), vim.log.levels.ERROR)
            end
        end
    end

    for name, config in pairs(language_configs) do
        languages[#languages + 1] = normalize(name, config)
    end

    local format = require("dot.format")
    local mason = require("dot.mason")
    local lint = require("dot.lint")
    local lsp = require("dot.lsp")
    local treesitter = require("dot.treesitter")

    for _, lang in ipairs(languages) do
        mason.ensure_installed(lang.ensure_installed)
        format.register_conform_filetype(lang.filetypes, lang.formatters_for_fts)
        format.register_conform_formatters(lang.formatters)
        lint.register_filetypes(lang.filetypes, lang.linters_for_fts)
        lint.register_linters(lang.linters)
        lsp.register_servers(lang.servers)
        treesitter.register_filetypes(lang.filetypes)
        treesitter.register_parsers(lang.treesitter_parsers)
    end
end

return M
