local lsp = require("dot.lsp")

local M = {}

M.ensure_installed = {
    "selene",
    "stylua",
}

M.skip_install = {}

---@param name string
---@return boolean
function M.skip_install(name)
    for _, skip in ipairs(M.skip_install) do
        if skip == name then
            return true
        end
    end

    return false
end

function M.install_servers()
    local Package = require("mason-core.package")

    for _, server_name in ipairs(lsp.get_server_names()) do
        if not M.skip_install(server_name) then
            local pkg_name, version = Package.Parse(server_name)
            resolve_package(pkg_name)
                :if_present(
                    ---@param pkg Package
                    function(pkg)
                        if not pkg:is_installed() and not pkg:is_installing() then
                            install(pkg, version)
                        end
                    end
                )
                :if_not_present(function()
                    vim.notify(("[mason] server %q is not a valid entry"):format(pkg_name), vim.log.levels.WARN)
                end)
        end
    end
end

function M.pack_specs()
    return {
        { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("2.2.1") },
    }
end

function M.setup()
    require("mason").setup()

    local mason_registry = require("mason-registry")

    mason_registry:on("package:install:success", function()
        vim.defer_fn(function()
            vim.api.nvim_exec_autocmds("FileType", {
                buffer = vim.api.nvim_get_current_buf(),
            })
        end, 100)
    end)

    mason_registry.refresh(vim.schedule_wrap(function()
        if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
            M.install_servers()

            for _, tool in ipairs(M.ensure_installed) do
                local pkg = mason_registry.get_package(tool)
                if not pkg:is_installed() and not pkg:is_installing() then
                    vim.notify(("[mason] installing %s"):format(tool))
                    pkg:install(
                        {},
                        vim.schedule_wrap(function(success)
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
