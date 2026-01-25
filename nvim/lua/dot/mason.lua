local lsp = require("dot.lsp")
local util = require("dot.util")

local M = {}

local cached_mason_specs = nil
local ensure_installed = {}
local skip_server_install = {}

---@param name string
---@return boolean
local function should_skip_install(name)
    for _, skip in ipairs(skip_server_install) do
        if skip == name then
            return true
        end
    end

    return false
end

local get_mason_map = util.memoize(function()
    local _ = require("mason-core.functional")

    cached_mason_specs = _.lazy(require("mason-registry").get_all_package_specs)

    ---@type table<string, string>
    local package_to_lspconfig = {}
    for _, pkg_spec in ipairs(cached_mason_specs()) do
        local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig")
        if lspconfig then
            package_to_lspconfig[pkg_spec.name] = lspconfig
        end
    end

    return {
        package_to_lspconfig = package_to_lspconfig,
        lspconfig_to_package = _.invert(package_to_lspconfig),
    }
end)

local function resolve_package(server_name)
    return require("mason-core.optional")
        .of_nilable(get_mason_map().lspconfig_to_package[server_name])
        :map(function(package_name)
            local ok, pkg = pcall(require("mason-registry").get_package, package_name)
            if ok then
                return pkg
            end
        end)
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

local function install_servers()
    local Package = require("mason-core.package")

    for _, server_name in ipairs(lsp.get_server_names()) do
        if not should_skip_install(server_name) then
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

function M.setup()
    require("mason").setup()

    local mason_registry = require("mason-registry")

    mason_registry:on("update:success", function()
        cached_mason_specs = require("mason-core.functional").lazy(mason_registry.get_all_package_specs)
    end)

    mason_registry:on("package:install:success", function()
        vim.defer_fn(function()
            vim.api.nvim_exec_autocmds("FileType", {
                buffer = vim.api.nvim_get_current_buf(),
            })
        end, 100)
    end)

    mason_registry.refresh(vim.schedule_wrap(function()
        if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
            install_servers()

            for _, tool in ipairs(ensure_installed) do
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

function M.pack_specs()
    return {
        { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("2.2.1") },
    }
end

---Register packages to be installed by Mason.
---@param pkgs string[]
function M.ensure_installed(pkgs)
    for _, pkg in ipairs(pkgs) do
        if not util.contains(ensure_installed, pkg) then
            ensure_installed[#ensure_installed + 1] = pkg
        end
    end
end

return M
