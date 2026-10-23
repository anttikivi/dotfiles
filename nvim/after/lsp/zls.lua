---@type vim.lsp.Config
return {
    cmd = { vim.fn.expand("~/.local/opt/zls/bin/zls") },
    settings = {
        zig_exe_path = vim.fn.expand("~/.local/opt/zig/zig"),
    },
}
