local languages = {
    "bash",
    "json",
    "lua",
}

require("nvim-treesitter.configs").setup({
    ensure_installed = languages,
    auto_install = false,
    highlight = { enable = true },
    indent = { enable = true },
})

-- TODO: Move to the main branch.
-- require("nvim-treesitter").install(languages)

-- vim.api.nvim_create_autocmd("FileType", {
--     -- TODO: Do I want to enable different tree-sitter features depending on
--     -- the language?
--     pattern = languages,
--     callback = function ()
--         vim.treesitter.start()
--         vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--     end
-- })
