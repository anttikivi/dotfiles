local M = {}

function M.pack_specs()
    return {
        { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("2.2.1") },
    }
end

function M.setup() end

return M
