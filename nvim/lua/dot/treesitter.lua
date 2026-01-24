local M = {}

---@type string[]
local filetypes = {}

---@type string[]
local parsers = {}

function M.setup()
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
        -- TODO: Do I want to enable different tree-sitter features depending on
        -- the language?
        pattern = filetypes,
        callback = function()
            vim.treesitter.start()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
    })
end

function M.pack_specs()
    return {
        {
            src = "https://github.com/nvim-treesitter/nvim-treesitter",
            version = "81aca2f9815e26f638f697df1d828ca290847b64",
        },
    }
end

-- Register the parsers and filetypes from the given language into Tree-sitter
-- configuration.
---@param name string The name of the language.
---@param lang dot.Language
function M.register_language(name, lang)
    ---@type string[]
    local fts = {}
    if type(lang.filetypes) == "string" then
        fts = {
            lang.filetypes --[[@as string]],
        }
    elseif type(lang.filetypes) == "table" then
        fts = lang.filetypes --[=[@as string[]]=]
    else
        fts = { name }
    end

    for _, ft in ipairs(fts) do
        local found = false
        for _, f in ipairs(filetypes) do
            if f == ft then
                found = true
            end
        end

        if not found then
            filetypes[#filetypes + 1] = ft
        end
    end

    ---@type string[]
    local lang_parsers = {}
    if type(lang.treesitter) == "string" then
        lang_parsers = {
            lang.treesitter --[[@as string]],
        }
    else
        lang_parsers = lang.treesitter --[=[@as string[]]=]
    end

    for _, parser in ipairs(lang_parsers) do
        local found = false
        for _, p in ipairs(parsers) do
            if p == parser then
                found = true
            end
        end

        if not found then
            parsers[#parsers + 1] = parser
        end
    end
end

return M
