local util = require("dot.util")

local M = {}

---@type string[]
local registered_filetypes = {}

---@type string[]
local registered_parsers = {}

function M.setup()
    require("nvim-treesitter").install(registered_parsers)

    vim.api.nvim_create_autocmd("FileType", {
        -- TODO: Do I want to enable different tree-sitter features depending on
        -- the language?
        pattern = registered_filetypes,
        callback = function()
            vim.treesitter.start()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
    })
end

---Run Tree-sitter for the given filetypes.
---@param filetypes string[]
function M.register_filetypes(filetypes)
    for _, ft in ipairs(filetypes) do
        if not util.contains(registered_filetypes, ft) then
            registered_filetypes[#registered_filetypes + 1] = ft
        end
    end
end

---Register the given parsers to be installed with Tree-sitter.
---@param parsers string[]
function M.register_parsers(parsers)
    for _, p in ipairs(parsers) do
        if not util.contains(registered_parsers, p) then
            registered_parsers[#registered_parsers + 1] = p
        end
    end
end

return M
