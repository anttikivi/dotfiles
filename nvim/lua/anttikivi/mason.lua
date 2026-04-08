local lsp = require("anttikivi.lsp")
local mason_registry = require("mason-registry")
local _ = require("mason-core.functional")

---@type string[]
local ensure_installed = {
    "ansible-lint",
    "clang-format",
    "gofumpt",
    "goimports",
    "golangci-lint",
    "oxfmt",
    "oxlint",
    "prettier",
    "selene",
    "shfmt",
    "stylua",
    "taplo",
    "yamllint",
}

require("mason").setup()

local cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)

mason_registry:on("update:success", function()
    cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)
end)

mason_registry:on("package:install:success", function()
    vim.defer_fn(function()
        vim.api.nvim_exec_autocmds("FileType", {
            buffer = vim.api.nvim_get_current_buf(),
        })
    end, 100)
end)

---@type table<string, string>
local package_to_lspconfig = {}
for _, pkg_spec in ipairs(cached_mason_specs()) do
    local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig")
    if lspconfig then
        package_to_lspconfig[pkg_spec.name] = lspconfig
    end
end

---@type table<string, string>
local lspconfig_to_package = _.invert(package_to_lspconfig)

local Optional = require("mason-core.optional")
local Package = require("mason-core.package")

mason_registry.refresh(vim.schedule_wrap(function()
    if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
        for _, server_name in ipairs(lsp.servers) do
            local parsed_name, version = Package.Parse(server_name)
            Optional.of_nilable(lspconfig_to_package[parsed_name])
                :map(function(name)
                    local ok, pkg = pcall(mason_registry.get_package, name)
                    if ok then
                        return pkg
                    end
                end)
                :if_present(
                    ---@param pkg Package
                    function(pkg)
                        if not pkg:is_installed() and not pkg:is_installing() then
                            local name = package_to_lspconfig[pkg.name]
                            vim.notify(("[mason] installing %s"):format(name))
                            pkg:install(
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
                    end
                )
                :if_not_present(function()
                    vim.notify(("[mason] server %q is not a valid entry"):format(parsed_name), vim.log.levels.WARN)
                end)
        end

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
