---@type vim.lsp.Config
return {
    cmd = { "tofu-ls", "serve" },
    filetypes = { "opentofu", "opentofu-vars", "terraform" },
    root_markers = { ".terraform", ".git" },
}
