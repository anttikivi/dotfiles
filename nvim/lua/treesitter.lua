-- TODO: Switch to this when there is better support for the new Tree-sitter
-- plugin version.

local languages = {
    "astro",
    "bash",
    "blade",
    "c",
    "cmake",
    "cpp",
    "css",
    "csv",
    "diff",
    "editorconfig",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "go",
    "gomod",
    "gosum",
    "gowork",
    "hcl",
    "html",
    "javascript",
    "jinja",
    "jinja_inline",
    "jsdoc",
    "json",
    "jsonc",
    "latex",
    "liquid",
    "lua",
    "luadoc",
    "luap",
    "make",
    "markdown",
    "markdown_inline",
    "nginx",
    "php",
    "python",
    "query",
    "r",
    "rust",
    "sql",
    "ssh_config",
    "superhtml",
    "svelte",
    "templ",
    "terraform",
    "tmux",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "xml",
    "yaml",
    "zig",
    "ziggy",
    "ziggy_schema",
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
