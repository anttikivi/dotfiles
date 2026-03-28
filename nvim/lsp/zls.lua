---@type vim.lsp.Config
return {
    cmd = { vim.fn.expand("~/.local/opt/zls/bin/zls") },
    filetypes = { "zig", "zir" },
    root_markers = { "zls.json", "build.zig", ".git" },
    workspace_required = false,
}
