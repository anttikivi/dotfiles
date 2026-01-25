local util = require("dot.util")

local M = {}

function M.setup()
    local specs = {}

    local path = vim.fn.stdpath("config") .. "/lua/dot/"
    local files = vim.fn.globpath(path, "*.lua", false, true)

    table.sort(files)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        if name ~= "init" then
            local module_name = "dot." .. name
            local ok, module = pcall(require, module_name)
            if ok then
                if type(module.pack_specs) == "function" then
                    vim.list_extend(specs, module.pack_specs())
                end
            else
                vim.notify(("[pack] failed to load %s: %s"):format(module_name, module), vim.log.levels.ERROR)
            end
        end
    end

    vim.pack.add(specs)

    -- Run required updates for plugins when they are updated.
    vim.api.nvim_create_autocmd("PackChanged", {
        group = util.augroup("pack_changed"),
        callback = function(ev)
            if ev.data.spec.name == "mason.nvim" then
                if ev.data.kind == "install" or ev.data.kind == "update" then
                    vim.cmd("MasonUpdate")
                end
            elseif ev.data.spec.name == "nvim-treesitter" then
                if ev.data.kind == "install" or ev.data.kind == "update" then
                    vim.cmd("TSUpdate")
                end
            end
        end,
    })
end

return M
