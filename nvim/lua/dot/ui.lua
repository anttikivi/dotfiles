local M = {}

function M.pack_specs()
    return {
        {
            src = "https://github.com/lewis6991/gitsigns.nvim",
            version = vim.version.range("2.0.0"),
        },
    }
end

return M
