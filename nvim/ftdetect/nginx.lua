local filetype_name = "nginx.jinja"

if vim.filetype then
    vim.filetype.add({
        pattern = {
            [".*%.conf%.j2"] = filetype_name,
            [".*mime%.types"] = "nginx",
        },
    })
else
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = {
            "*.conf.j2",
        },
        callback = function()
            vim.bo.filetype = filetype_name
        end,
    })
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = {
            "mime.types",
        },
        callback = function()
            vim.bo.filetype = "nginx"
        end,
    })
end
