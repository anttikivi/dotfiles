local config = require("dot.config")

local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

function M.check()
    start("dot")

    if not vim.version.cmp then
        error(
            string.format(
                "Neovim out of date: '%s'. This configuration requires at least Neovim version 0.12.0",
                tostring(vim.version())
            )
        )
        return
    end

    -- if vim.version.cmp(vim.version(), { 0, 12, 0 }) >= 0 then
    if
        vim.version.cmp(vim.version(), vim.version.parse("0.12.0-dev") --[[@as vim.Version]]) >= 0
    then
        ok(string.format("Neovim version is: '%s'", tostring(vim.version())))
    else
        error(
            string.format(
                "Neovim out of date: '%s'. This configuration requires at least Neovim version 0.12.0",
                tostring(vim.version())
            )
        )
    end

    if config.cmp == "native" then
        ok("cmp: native")
    elseif config.cmp == "nvim-cmp" then
        ok("cmp: nvim-cmp")
    else
        error(string.format("invalid cmp: '%s'", config.cmp))
    end

    if config.file_explorer == "netrw" then
        ok("file_explorer: netrw")
    elseif config.file_explorer == "oil" then
        ok("file_explorer: oil.nvim")
    else
        error(string.format("invalid file_explorer: '%s'", config.file_explorer))
    end

    if config.picker == "telescope" then
        ok("file_explorer: telescope")
    else
        error(string.format("invalid picker: '%s'", config.picker))
    end
end

return M
