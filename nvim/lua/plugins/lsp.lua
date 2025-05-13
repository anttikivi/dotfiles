local diagnostics_icons = require("config.icons").diagnostics
local lsp_keymaps = require("config.lsp_keymaps")
local lsp_util = require("util.lsp")

---@module 'lspconfig'
---@class ServerConfig: lspconfig.Config
---@field cmd? lspconfig.Config.command

local tools = {
  "ansible-lint",
  "blade-formatter",
  "codelldb",
  "goimports",
  "gofumpt",
  "hadolint",
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

if vim.g.rust_diagnostics == "bacon-ls" then
  vim.list_extend(tools, { "bacon", "bacon-ls" })
end

return {
  {
    "mason-org/mason.nvim",
    ---@param opts MasonSettings
    config = function(_, opts)
      require("mason").setup(opts)

      local mason_registry = require("mason-registry")

      mason_registry:on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mason_registry.refresh(function()
        for _, tool in ipairs(tools) do
          local p = mason_registry.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
    build = ":MasonUpdate",
    cmd = "Mason",
    version = "^1.0.0", -- TODO: Update the LSP config.
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      {
        "mason-org/mason-lspconfig.nvim",
        config = function() end,
        version = "^1.0.0", -- TODO: Update the LSP config.
      },
    },
    opts = function()
      ---@class PluginLspOpts
      local opts = {
        ---@type vim.diagnostic.Opts
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = "if_many",
            prefix = "icons",
          },
          severity_sort = true,
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = diagnostics_icons.error,
              [vim.diagnostic.severity.WARN] = diagnostics_icons.warn,
              [vim.diagnostic.severity.INFO] = diagnostics_icons.info,
              [vim.diagnostic.severity.HINT] = diagnostics_icons.hint,
            },
          },
        },
        inlay_hints = {
          enabled = true,
          exclude = {}, -- e.g. {"vue", "go"}
        },
        codelens = {
          enabled = false,
        },
        capabilities = {
          workspace = {
            fileOperations = {
              didRename = true,
              willRename = true,
            },
          },
        },
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        ---@type table<string, boolean | ServerConfig>
        servers = {
          ansiblels = {},
          astro = {},
          bacon_ls = {
            enabled = vim.g.rust_diagnostics == "bacon-ls",
          },
          basedpyright = {},
          clangd = {
            root_dir = function(fname)
              ---@diagnostic disable-next-line: redundant-return-value
              return require("lspconfig.util").root_pattern(
                "Makefile",
                "configure.ac",
                "configure.in",
                "config.h.in",
                "meson.build",
                "meson_options.txt",
                "build.ninja"
              )(fname) or require("lspconfig.util").root_pattern(
                "compile_commands.json",
                "compile_flags.txt"
              )(fname) or vim.fs.dirname(
                vim.fs.find(".git", { path = fname, upward = true })[1]
              )
            end,
            capabilities = {
              offsetEncoding = { "utf-16" },
            },
            cmd = {
              "clangd",
              "--background-index",
              "--clang-tidy",
              "--header-insertion=iwyu",
              "--completion-style=detailed",
              "--function-arg-placeholders",
              "--fallback-style=llvm",
            },
            init_options = {
              usePlaceholders = true,
              completeUnimported = true,
              clangdFileStatus = true,
            },
          },
          css_variables = {},
          cssls = {},
          dockerls = {},
          docker_compose_language_service = {},
          eslint = {
            settings = {
              workingDirectories = { mode = "auto" },
              format = vim.g.eslint_auto_format,
            },
          },
          gopls = {
            settings = {
              gopls = {
                gofumpt = true,
                codelenses = {
                  gc_details = false,
                  generate = true,
                  regenerate_cgo = true,
                  run_govulncheck = true,
                  test = true,
                  tidy = true,
                  upgrade_dependency = true,
                  vendor = true,
                },
                hints = {
                  assignVariableTypes = true,
                  compositeLiteralFields = true,
                  compositeLiteralTypes = true,
                  constantValues = true,
                  functionTypeParameters = true,
                  parameterNames = true,
                  rangeVariableTypes = true,
                },
                analyses = {
                  nilness = true,
                  unusedparams = true,
                  unusedwrite = true,
                  useany = true,
                },
                usePlaceholders = true,
                completeUnimported = true,
                staticcheck = true,
                directoryFilters = {
                  "-.git",
                  "-.vscode",
                  "-.idea",
                  "-.vscode-test",
                  "-node_modules",
                },
                semanticTokens = true,
              },
            },
          },
          intelephense = {
            enabled = vim.g.php_lsp == "intelephense",
          },
          jsonls = {
            on_new_config = function(new_config)
              ---@diagnostic disable-next-line: inject-field
              new_config.settings.json.schemas = new_config.settings.json.schemas
                or {}
              vim.list_extend(
                new_config.settings.json.schemas,
                require("schemastore").json.schemas()
              )
            end,
            settings = {
              json = {
                format = {
                  enable = true,
                },
                validate = { enable = true },
              },
            },
          },
          lua_ls = {
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                },
                codeLens = {
                  enable = true,
                },
                completion = {
                  callSnippet = "Replace",
                },
                doc = {
                  privateName = { "^_" },
                },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          },
          marksman = {},
          phpactor = {
            enabled = vim.g.php_lsp == "phpactor",
          },
          ruff = {
            cmd_env = { RUFF_TRACE = "messages" },
            init_options = {
              settings = {
                logLevel = "error",
              },
            },
            keys = {
              {
                "<leader>co",
                lsp_util.action["source.organizeImports"],
                desc = "Organize Imports",
              },
            },
          },
          rust_analyzer = {
            settings = {
              ["rust-analyzer"] = {
                checkOnSave = {
                  enabled = vim.g.rust_diagnostics == "rust-analyzer",
                },
                diagnostics = {
                  enabled = vim.g.rust_diagnostics == "rust-analyzer",
                },
              },
            },
          },
          tailwindcss = {},
          taplo = {},
          terraformls = {},
          vtsls = {
            filetypes = {
              "javascript",
              "javascriptreact",
              "javascript.jsx",
              "typescript",
              "typescriptreact",
              "typescript.tsx",
            },
            settings = {
              complete_function_calls = true,
              vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                  maxInlayHintLength = 30,
                  completion = {
                    enableServerSideFuzzyMatch = true,
                  },
                },
                tsserver = {
                  globalPlugins = {
                    {
                      name = "@astrojs/ts-plugin",
                      location = require("util").get_pkg_path(
                        "astro-language-server",
                        "/node_modules/@astrojs/ts-plugin"
                      ),
                      enableForWorkspaceTypeScriptVersions = true,
                    },
                  },
                },
              },
              typescript = {
                updateImportsOnFileMove = { enabled = "always" },
                suggest = {
                  completeFunctionCalls = true,
                },
                inlayHints = {
                  enumMemberValues = { enabled = true },
                  functionLikeReturnTypes = { enabled = true },
                  parameterNames = { enabled = "literals" },
                  parameterTypes = { enabled = true },
                  propertyDeclarationTypes = { enabled = true },
                  variableTypes = { enabled = false },
                },
              },
            },
            keys = {
              {
                "gD",
                function()
                  ---@diagnostic disable-next-line: missing-parameter
                  local params = vim.lsp.util.make_position_params()
                  lsp_util.execute({
                    command = "typescript.goToSourceDefinition",
                    arguments = { params.textDocument.uri, params.position },
                    open = true,
                  })
                end,
                desc = "Goto Source Definition",
              },
              {
                "gR",
                function()
                  lsp_util.execute({
                    command = "typescript.findAllFileReferences",
                    arguments = { vim.uri_from_bufnr(0) },
                    open = true,
                  })
                end,
                desc = "File References",
              },
              {
                "<leader>co",
                lsp_util.action["source.organizeImports"],
                desc = "Organize Imports",
              },
              {
                "<leader>cM",
                lsp_util.action["source.addMissingImports.ts"],
                desc = "Add missing imports",
              },
              {
                "<leader>cu",
                lsp_util.action["source.removeUnused.ts"],
                desc = "Remove unused imports",
              },
              {
                "<leader>cD",
                lsp_util.action["source.fixAll.ts"],
                desc = "Fix all diagnostics",
              },
              {
                "<leader>cV",
                function()
                  lsp_util.execute({
                    command = "typescript.selectTypeScriptVersion",
                  })
                end,
                desc = "Select TS workspace version",
              },
            },
          },
          yamlls = {
            capabilities = {
              textDocument = {
                foldingRange = {
                  dynamicRegistration = false,
                  lineFoldingOnly = true,
                },
              },
            },
            on_new_config = function(new_config)
              ---@diagnostic disable-next-line: inject-field
              new_config.settings.yaml.schemas = vim.tbl_deep_extend(
                "force",
                new_config.settings.yaml.schemas or {},
                require("schemastore").yaml.schemas()
              )
            end,
            settings = {
              redhat = { telemetry = { enabled = false } },
              yaml = {
                keyOrdering = false,
                format = {
                  enable = true,
                },
                validate = true,
              },
            },
          },
          zls = {},
          [vim.g.php_lsp] = {
            enabled = true,
          },
        },
        setup = {
          eslint = function()
            if not vim.g.eslint_auto_format then
              return
            end

            local formatter = lsp_util.formatter({
              name = "eslint: lsp",
              primary = false,
              priority = 200,
              filter = "eslint",
            })

            require("util.format").register(formatter)
          end,
          gopls = function()
            -- Workaround for gopls not supporting semanticTokensProvider:
            -- https://github.com/golang/go/issues/54531#issuecomment-1464982242
            lsp_util.on_attach(function(client, _)
              if not client.server_capabilities.semanticTokensProvider then
                local semantic =
                  client.config.capabilities.textDocument.semanticTokens
                client.server_capabilities.semanticTokensProvider = {
                  full = true,
                  legend = {
                    ---@diagnostic disable-next-line: need-check-nil
                    tokenTypes = semantic.tokenTypes,
                    ---@diagnostic disable-next-line: need-check-nil
                    tokenModifiers = semantic.tokenModifiers,
                  },
                  range = true,
                }
              end
            end, "gopls")
            -- end workaround
          end,
          ruff = function()
            lsp_util.on_attach(function(client, _)
              -- Disable hover in favor of (based)pyright
              client.server_capabilities.hoverProvider = false
            end, "ruff")
          end,
          vtsls = function(_, opts)
            lsp_util.on_attach(function(client)
              client.commands["_typescript.moveToFileRefactoring"] = function(
                command
              )
                ---@type string, string, lsp.Range
                ---@diagnostic disable-next-line: assign-type-mismatch
                local action, uri, range = unpack(command.arguments)

                local function move(newf)
                  ---@diagnostic disable-next-line: param-type-mismatch
                  client.request("workspace/executeCommand", {
                    command = command.command,
                    arguments = { action, uri, range, newf },
                  })
                end

                ---@diagnostic disable-next-line: param-type-mismatch
                local fname = vim.uri_to_fname(uri)

                ---@diagnostic disable-next-line: param-type-mismatch
                client.request("workspace/executeCommand", {
                  command = "typescript.tsserverRequest",
                  arguments = {
                    "getMoveToRefactoringFileSuggestions",
                    {
                      file = fname,
                      ---@diagnostic disable-next-line: need-check-nil, undefined-field
                      startLine = range.start.line + 1,
                      ---@diagnostic disable-next-line: need-check-nil, undefined-field
                      startOffset = range.start.character + 1,
                      ---@diagnostic disable-next-line: need-check-nil, undefined-field
                      endLine = range["end"].line + 1,
                      ---@diagnostic disable-next-line: need-check-nil, undefined-field
                      endOffset = range["end"].character + 1,
                    },
                  },
                  ---@diagnostic disable-next-line: param-type-mismatch
                }, function(_, result)
                  ---@type string[]
                  local files = result.body.files
                  table.insert(files, 1, "Enter new path...")
                  vim.ui.select(files, {
                    prompt = "Select move destination:",
                    format_item = function(f)
                      return vim.fn.fnamemodify(f, ":~:.")
                    end,
                  }, function(f)
                    if f and f:find("^Enter new path") then
                      vim.ui.input({
                        prompt = "Enter move destination:",
                        default = vim.fn.fnamemodify(fname, ":h") .. "/",
                        completion = "file",
                      }, function(newf)
                        return newf and move(newf)
                      end)
                    elseif f then
                      move(f)
                    end
                  end)
                end)
              end
            end, "vtsls")

            opts.settings.javascript = vim.tbl_deep_extend(
              "force",
              {},
              opts.settings.typescript,
              opts.settings.javascript or {}
            )
          end,
        },
      }

      local keys = lsp_keymaps.get()

      if vim.g.finder == "telescope" then
        local builtin = require("telescope.builtin")

        vim.list_extend(keys, {
          {
            "gd",
            function()
              builtin.lsp_definitions({ reuse_win = true })
            end,
            desc = "Goto definition",
            has = "definition",
          },
          {
            "gr",
            "<cmd>Telescope lsp_references<cr>",
            desc = "References",
            nowait = true,
          },
          {
            "gI",
            function()
              builtin.lsp_implementations({
                reuse_win = true,
              })
            end,
            desc = "Goto implementation",
          },
          {
            "gy",
            function()
              builtin.lsp_type_definitions({
                reuse_win = true,
              })
            end,
            desc = "Goto type Definition",
          },
        })
      end

      return opts
    end,
    ---@param opts PluginLspOpts
    config = function(_, opts)
      require("util.format").register(lsp_util.formatter())
      lsp_util.on_attach(lsp_keymaps.on_attach)
      lsp_util.setup()
      lsp_util.on_dynamic_capability(lsp_keymaps.on_attach)

      if opts.inlay_hints.enabled then
        lsp_util.on_supports_method(
          "textDocument/inlayHint",
          function(_, buffer)
            if
              vim.api.nvim_buf_is_valid(buffer)
              and vim.bo[buffer].buftype == ""
              and not vim.tbl_contains(
                opts.inlay_hints.exclude,
                vim.bo[buffer].filetype
              )
            then
              vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
            end
          end
        )
      end

      if opts.codelens.enabled and vim.lsp.codelens then
        lsp_util.on_supports_method("textDocument/codeLens", function(_, buffer)
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd(
            { "BufEnter", "CursorHold", "InsertLeave" },
            {
              buffer = buffer,
              callback = vim.lsp.codelens.refresh,
            }
          )
        end)
      end

      if
        type(opts.diagnostics.virtual_text) == "table"
        and opts.diagnostics.virtual_text.prefix == "icons"
      then
        opts.diagnostics.virtual_text.prefix = function(diagnostic)
          for d, icon in pairs(diagnostics_icons) do
            ---@diagnostic disable-next-line: undefined-field
            if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              return icon
            end
          end

          -- TODO: The function should return something, so this is given as the
          -- default value. Maybe time will tell if this is wise.
          return "●"
        end
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local servers = opts.servers
      -- NOTE: Right now, I only want to support cmp. Still, I do this in this
      -- way so that I can easily try out more engines (mainly blink) in the
      -- future.
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        opts.capabilities or {}
      )
      local mason_lspconfig = require("mason-lspconfig")
      local mason_servers = vim.tbl_keys(
        require("mason-lspconfig.mappings.server").lspconfig_to_package
      )
      local ensure_installed = {} ---@type string[]

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})

        if server_opts.enabled == false then
          return
        end

        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end

        require("lspconfig")[server].setup(server_opts)
      end

      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- Explicitly check if the boolean is false as the server is enabled
          -- if the option is not set.
          if server_opts.enabled ~= false then
            if
              server_opts.mason == false
              or not vim.tbl_contains(mason_servers, server)
            then
              setup(server)
            else
              ensure_installed[#ensure_installed + 1] = server
            end
          end
        end
      end

      mason_lspconfig.setup({
        -- NOTE: Automatic installation is `false` by default.
        automatic_installation = false,
        ensure_installed = vim.tbl_deep_extend(
          "force",
          ensure_installed,
          require("util.plugin").opts("mason-lspconfig.nvim").ensure_installed
            or {}
        ),
        handlers = { setup },
      })
    end,
    event = "LazyFile",
  },
}
