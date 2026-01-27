---@type dot.languages.Config
return {
    linters = "tofu",
    servers = {
        tofu_ls = {
            cmd = { "tofu-ls", "serve" },
            filetypes = { "opentofu", "opentofu-vars", "terraform" },
            root_markers = { ".terraform", ".git" },
        },
    },
    skip_install = "tofu",
    treesitter = { "terraform", "hcl" },
}
