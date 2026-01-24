local M = {}

---@class dot.Language
---@field ensure_installed string[]?
---@field formatters string[]?
---@field linters string[]?
---@field servers table<string, dot.lsp.Config>?
---@field treesitter string[]?

---@type dot.Language[]
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
                languages[#languages + 1] = module
            else
                vim.notify(("[languages] failed to load %s: %s"):format(module_name, module), vim.log.levels.ERROR)
            end
        end
    end

    local mason = require("dot.mason")
    local lsp = require("dot.lsp")

    for _, lang in ipairs(languages) do
        if lang.ensure_installed ~= nil then
            for _, pkg in ipairs(lang.ensure_installed) do
                mason.ensure_installed(pkg)
            end
        end

        if lang.servers ~= nil then
            for name, server in pairs(lang.servers) do
                lsp.register_server(name, server)
            end
        end
    end
end

return M
