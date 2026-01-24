local M = {}

function M.setup()
    local pack_specs = {}

    vim.list_extend(pack_specs, require("dot.explorer").pack_specs())
    vim.list_extend(pack_specs, require("dot.lsp").pack_specs())
    vim.list_extend(pack_specs, require("dot.mason").pack_specs())

    vim.pack.add(pack_specs)
end

return M
