local filetype_name = "json.jinja"

if vim.filetype then
    vim.filetype.add({
        pattern = {
            [".*%.json%.j2"] = filetype_name,
        },
    })
else
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = {
            "*.json.j2",
        },
        callback = function()
            vim.bo.filetype = filetype_name
        end,
    })
end
