local diagnostics_icons = require("config.icons").diagnostics
local lsp_keymaps = require("config.lsp_keymaps")
local lsp_util = require("util.lsp")

---@module 'lspconfig'
---@class ServerConfig: lspconfig.Config
---@field cmd? lspconfig.Config.command

---@type string[]
local tools = { "stylua" }

return {
  {
    "williamboman/mason.nvim",
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
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      { "williamboman/mason-lspconfig.nvim", config = function() end },
    },
    opts = function()
      ---@class PluginLspOpts
      local ret = {
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
        },
        setup = {},
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

      return ret
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
  },
}
