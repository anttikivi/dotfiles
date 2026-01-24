-- TODO: Check what's up with these root markers. Right now, this configuration is just from nvim-lspconfig.
local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

---@type dot.Language
return {
    ensure_installed = { "selene", "stylua" },
    filetypes = { "lua" },
    linters = {
        selene = {
            condition = function()
                local root = require("dot.root").get({ normalize = true })
                if root ~= vim.uv.cwd() then
                    return false
                end
                return vim.fs.find({ "selene.toml" }, { path = root, upward = true })[1]
            end,
        },
    },
    servers = {
        lua_ls = {
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
            root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers1, root_markers2, { ".git" } }
                or vim.list_extend(vim.list_extend(root_markers1, root_markers2), { ".git" }),
            settings = {
                Lua = {
                    codeLens = { enable = true },
                    hint = { enable = true, semicolon = "Disable" },
                },
            },
        },
    },
    treesitter = { "lua" },
}
