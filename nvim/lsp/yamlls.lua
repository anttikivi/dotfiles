---@type vim.lsp.Config
return {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
    root_markers = { ".git" },
    ---@type lspconfig.settings.yamlls
    settings = {
        redhat = { telemetry = { enabled = false } },
        -- formatting disabled by default in yaml-language-server; enable it
        yaml = {
            format = {
                enable = false,
            },
            customTags = {
                "!Condition sequence",
                "!Context scalar",
                "!Enumerate sequence",
                "!Env scalar",
                "!File scalar",
                "!File sequence",
                "!Find sequence",
                "!Format sequence",
                "!If sequence",
                "!Index scalar",
                "!KeyOf scalar",
                "!Value scalar",
                "!AtIndex scalar",
            },
        },
    },
    on_init = function(client)
        --- https://github.com/neovim/nvim-lspconfig/pull/4016
        --- Since formatting is disabled by default if you check `client:supports_method('textDocument/formatting')`
        --- during `LspAttach` it will return `false`. This hack sets the capability to `true` to facilitate
        --- autocmd's which check this capability
        client.server_capabilities.documentFormattingProvider = true
    end,
}
