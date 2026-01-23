local explorer = require("explorer")

local M = {}

function M.setup()
    local pack_specs = {}

    vim.list_extend(pack_specs, explorer.pack_specs())

    vim.pack.add(pack_specs)
end

return M
