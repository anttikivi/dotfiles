local mason_registry = require("mason-registry")

local ensure_installed = {
    "prettier",
    "selene",
    "stylua",
}

local M = {}

function M.init()
    require("mason").setup()

    mason_registry.refresh(vim.schedule_wrap(function(success, updated_registries)
        if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
            require("util.mason").install_servers()

            for _, tool in ipairs(ensure_installed) do
                local pkg = mason_registry.get_package(tool)
                if not pkg:is_installed() and not pkg:is_installing() then
                    vim.notify(("[mason] installing %s"):format(tool))
                    pkg:install(
                        {},
                        vim.schedule_wrap(function(success, err)
                            if success then
                                vim.notify(("[mason] %s was successfully installed"):format(tool))
                            else
                                vim.notify(
                                    ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                                        tool
                                    ),
                                    vim.log.levels.ERROR
                                )
                            end
                        end)
                    )
                end
            end
        end
    end))
end

return M
