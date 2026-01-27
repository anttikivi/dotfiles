local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

function M.check()
    start("config")

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

    if vim.g.cmp == "native" then
        ok("cmp: native")
    elseif vim.g.cmp == "nvim-cmp" then
        ok("cmp: nvim-cmp")
    else
        error(string.format("invalid cmp: '%s'", vim.g.cmp))
    end

    if vim.g.file_explorer == "netrw" then
        ok("file_explorer: netrw")
    elseif vim.g.file_explorer == "oil" then
        ok("file_explorer: oil.nvim")
    else
        error(string.format("invalid file_explorer: '%s'", vim.g.file_explorer))
    end

    if vim.g.picker == "telescope" then
        ok("file_explorer: telescope")
    else
        error(string.format("invalid picker: '%s'", vim.g.picker))
    end
end

return M
