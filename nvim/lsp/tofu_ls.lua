---@type config.LspConfig
return {
    enabled = false,
    cmd = { "tofu-ls", "serve" },
    filetypes = { "opentofu", "opentofu-vars", "terraform" },
    root_markers = { ".terraform", ".git" },
}
