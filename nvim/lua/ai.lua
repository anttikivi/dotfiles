local config = require("config")

local M = {}

function M.pack_spec()
    if not config.ai_enabled then
        return {}
    end

    if config.ai_engine == "supermaven" then
        return {
            { src = "https://github.com/supermaven-inc/supermaven-nvim" },
        }
    end

    vim.notify(("Invalid value for `config.ai_engine`: %q"):format(config.ai_engine), vim.log.levels.ERROR)

    return {}
end

function M.setup()
    if not config.ai_enabled then
        return
    end

    if config.ai_engine == "supermaven" then
        require("supermaven-nvim").setup({})
    end
end

return M
