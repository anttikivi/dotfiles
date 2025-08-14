local _ = require("mason-core.functional")
local config = require("config")
local mason_registry = require("mason-registry")
local Package = require("mason-core.package")

local M = {}

local ensure_installed = {
    "ansible-lint",
    "blade-formatter",
    "goimports",
    "gofumpt",
    "markdownlint-cli2",
    "markdown-toc",
    "phpcs",
    "php-cs-fixer",
    "pint",
    "prettier",
    "selene",
    "stylua",
    "tflint",
}

local skip_install = {
    "superhtml",
    "ziggy",
    "ziggy_schema",
}

---@class Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

local cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)
mason_registry:on("update:success", function()
    cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)
end)

local function get_mason_map()
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
end

local function resolve_package(server_name)
    local Optional = require("mason-core.optional")
    local server_mapping = get_mason_map()

    return Optional.of_nilable(server_mapping.lspconfig_to_package[server_name]):map(function(package_name)
        local ok, pkg = pcall(mason_registry.get_package, package_name)
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

---@param name string
---@return boolean
local function should_skip_install(name)
    for _, skip in ipairs(skip_install) do
        if skip == name then
            return true
        end
    end

    return false
end

local function install_servers()
    for _, server_name in ipairs(M.server_names()) do
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

---@param filter? Filter
---@return vim.lsp.Client[]
function M.get_clients(filter)
    local clients = vim.lsp.get_clients(filter)
    return filter and filter.filter and vim.tbl_filter(filter.filter, clients) or clients
end

function M.get_typescript_server_path(root_dir)
    local project_roots = vim.fs.find("node_modules", { path = root_dir, upward = true, limit = math.huge })
    for _, project_root in ipairs(project_roots) do
        local typescript_path = project_root .. "/typescript"
        local stat = vim.uv.fs_stat(typescript_path)
        if stat and stat.type == "directory" then
            return typescript_path .. "/lib"
        end
    end
    return ""
end

-- Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param fn fun(client: vim.lsp.Client, buf: integer)
---@param name? string
function M.on_attach(fn, name)
    return vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local buffer = args.buf ---@type integer
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and (not name or client.name == name) then
                fn(client, buffer)
            end
        end,
    })
end

---@return string[]
local function get_server_names()
    local ret = {}
    for name, type in vim.fs.dir(vim.fn.stdpath("config") .. "/lsp") do
        if type == "file" and name:sub(-4) == ".lua" then
            ret[#ret + 1] = name:gsub("%.lua$", "")
        end
    end

    return ret
end

M.server_names = require("util").memoize(get_server_names)

function M.setup()
    require("mason").setup()

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

    vim.lsp.enable(M.server_names())

    require("formatting").register({
        name = "LSP",
        primary = true,
        priority = 1,
        format = function(buf)
            vim.lsp.buf.format({ timeout_ms = config.formatting_timeout_ms, bufnr = buf })
        end,
        sources = function(buf)
            local clients = M.get_clients({ bufnr = buf })
            ---@param client vim.lsp.Client
            local ret = vim.tbl_filter(function(client)
                return client:supports_method("textDocument/formatting")
                    or client:supports_method("textDocument/rangeFormatting")
            end, clients)
            ---@param client vim.lsp.Client
            return vim.tbl_map(function(client)
                return client.name
            end, ret)
        end,
    })

    M.on_attach(function(_, buffer)
        -- Neovim now provides some default mappings so I don't need to add my
        -- own:
        -- "grn": vim.lsp.buf.rename()
        -- "gra": vim.lsp.buf.code_action()
        -- "grr": vim.lsp.buf.references()
        -- "gri": vim.lsp.buf.implementation()
        -- "grt": vim.lsp.buf.type_definition()
        -- "gO": vim.lsp.buf.document_symbol()
        -- CTRL-S: vim.lsp.buf.signature_help()
        vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = buffer })
    end)
    M.on_attach(function(client, buffer)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
    end)

    ---@type vim.diagnostic.Opts
    local diagnostic_config = {
        signs = {
            text = config.enable_icons and {
                [vim.diagnostic.severity.ERROR] = config.icons.diagnostics.error,
                [vim.diagnostic.severity.WARN] = config.icons.diagnostics.warn,
                [vim.diagnostic.severity.INFO] = config.icons.diagnostics.info,
                [vim.diagnostic.severity.HINT] = config.icons.diagnostics.hint,
            } or {
                [vim.diagnostic.severity.ERROR] = "E",
                [vim.diagnostic.severity.WARN] = "W",
                [vim.diagnostic.severity.INFO] = "I",
                [vim.diagnostic.severity.HINT] = "H",
            },
        },
        virtual_text = true,
    }

    vim.diagnostic.config(diagnostic_config)
end

return M
