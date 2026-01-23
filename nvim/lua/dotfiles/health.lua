local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

function M.check()
    start("dotfiles")

    if not vim.version.cmp then
        error(
            string.format(
                "Neovim out of date: '%s'. This configuration requires at least Neovim version 0.12.0",
                tostring(vim.version())
            )
        )
        return
    end

    if vim.version.cmp(vim.version(), { 0, 12, 0 }) >= 0 then
        ok(string.format("Neovim version is: '%s'", tostring(vim.version())))
    else
        error(
            string.format(
                "Neovim out of date: '%s'. This configuration requires at least Neovim version 0.12.0",
                tostring(vim.version())
            )
        )
    end
end

return M
