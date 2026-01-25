local config = require("dot.config")
local M = {}

function M.setup()
    vim.diagnostic.config({
        signs = {
            text = config.enable_icons and {
                [vim.diagnostic.severity.ERROR] = config.icons.diagnostics.error,
                [vim.diagnostic.severity.WARN] = config.icons.diagnostics.warn,
                [vim.diagnostic.severity.INFO] = config.icons.diagnostics.info,
                [vim.diagnostic.severity.HINT] = config.icons.diagnostics.hint,
            } or {
                [vim.diagnostic.severity.ERROR] = "E",
                [vim.diagnostic.severity.WARN] = "W",
                [vim.diagnostic.severity.INFO] = "I",
                [vim.diagnostic.severity.HINT] = "H",
            },
        },
        virtual_text = true,
    })
end

return M
