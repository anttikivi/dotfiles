local languages = {
    "bash",
    "json",
    "lua",
}

require("nvim-treesitter").install(languages)

vim.api.nvim_create_autocmd("FileType", {
    -- TODO: Do I want to enable different tree-sitter features depending on
    -- the language?
    pattern = languages,
    callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
