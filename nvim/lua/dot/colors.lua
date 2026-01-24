local M = {}

function M.setup()
    require("auto-dark-mode").setup({ update_interval = 5000 })
    vim.cmd.colorscheme("lucid")
end

function M.pack_specs()
    return {
        { src = "https://github.com/anttikivi/lucid.nvim", version = "b8dac7949c93a824e353bbd24f188b27ebdf8512" },
        {
            src = "https://github.com/f-person/auto-dark-mode.nvim",
            version = "e300259ec777a40b4b9e3c8e6ade203e78d15881",
        },
    }
end

return M
