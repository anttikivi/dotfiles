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
    formatters = { "stylua" },
    linters = {
        selene = {
            condition = function()
                return vim.fs.find(
                    { "selene.toml" },
                    { path = require("dot.root").get({ normalize = true }), upward = true }
                )[1]
            end,
        },
    },
    servers = {
        lua_ls = {
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
            root_markers = { root_markers1, root_markers2, { ".git" } },
            on_init = function(client)
                if client.workspace_folders then
                    local path = client.workspace_folders[1].name
                    if
                        path ~= vim.fn.stdpath("config")
                        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                    then
                        return
                    end
                end

                client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua --[[@as table]], {
                    runtime = {
                        version = "LuaJIT",
                        path = {
                            "lua/?.lua",
                            "lua/?/init.lua",
                        },
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME,
                        },
                    },
                })
            end,
            settings = {
                Lua = {
                    codeLens = {
                        enable = true,
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                    doc = {
                        privateName = { "^_" },
                    },
                    hint = {
                        enable = true,
                        setType = false,
                        paramType = true,
                        paramName = "Disable",
                        semicolon = "Disable",
                        arrayIndex = "Disable",
                    },
                },
            },
        },
    },
    treesitter = { "lua" },
}
