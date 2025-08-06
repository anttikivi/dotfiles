local _ = require("mason-core.functional")
local Package = require("mason-core.package")
local registry = require("mason-registry")

local M = {}

local cached_specs = _.lazy(registry.get_all_package_specs)
registry:on("update:success", function()
    cached_specs = _.lazy(registry.get_all_package_specs)
end)

local function get_mason_map()
    ---@type table<string, string>
    local package_to_lspconfig = {}
    for _, pkg_spec in ipairs(cached_specs()) do
        local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig")
        if lspconfig then
            package_to_lspconfig[pkg_spec.name] = lspconfig
        end
    end

    return {
        package_to_lspconfig = package_to_lspconfig,
        lspconfig_to_package = _.invert(package_to_lspconfig),
    }
end

local function install(pkg, version)
    local name = get_mason_map().package_to_lspconfig[pkg.name]
    vim.notify(("[mason] installing %s"):format(name))
    return pkg:install(
        { version = version },
        vim.schedule_wrap(function(success)
            if success then
                vim.notify(("[mason] %s was successfully installed"):format(name))
            else
                vim.notify(
                    ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                        name
                    ),
                    vim.log.levels.ERROR
                )
            end
        end)
    )
end

local function resolve_package(server_name)
    local Optional = require("mason-core.optional")
    local server_mapping = get_mason_map()

    return Optional.of_nilable(server_mapping.lspconfig_to_package[server_name]):map(function(package_name)
        local ok, pkg = pcall(registry.get_package, package_name)
        if ok then
            return pkg
        end
    end)
end

function M.install_servers()
    for _, server_name in ipairs(require("util.lsp").server_names()) do
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

return M
