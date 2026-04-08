local parsers = {
    "astro",
    "awk",
    "bash",
    "c",
    "cpp",
    "css",
    "go",
    "gomod",
    "gosum",
    "gowork",
    "javascript",
    "json",
    "jsx",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "powershell",
    "python",
    "terraform",
    "tsx",
    "typescript",
    "toml",
    "vim",
    "xml",
    "yaml",
    "zig",
    "zsh",
}

require("nvim-treesitter").install(parsers)

---@type string[]
local autocmd_pattern = {}

for i, l in ipairs(parsers) do
    if l == "terraform" then
        autocmd_pattern[i] = "opentofu"
    else
        autocmd_pattern[i] = l
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = autocmd_pattern,
    callback = function(ev)
        if not pcall(vim.treesitter.start) then
            vim.notify(string.format("failed to start Tree-sitter for %s", ev.match), vim.log.levels.WARN)
        end
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo[0][0].foldmethod = "expr"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

vim.treesitter.language.register("terraform", { "opentofu" })
