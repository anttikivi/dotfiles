return {
  {
    "stevearc/conform.nvim",
    dependencies = { "williamboman/mason.nvim" },
    init = function()
      require("util.event").on_very_lazy(function()
        require("util.format").register({
          name = "conform.nvim",
          priority = 100,
          primary = true,
          format = function(buf)
            require("conform").format({ bufnr = buf })
          end,
          sources = function(buf)
            local ret = require("conform").list_formatters(buf)
            ---@param v conform.FormatterInfo
            return vim.tbl_map(function(v)
              return v.name
            end, ret)
          end,
        })
      end)
    end,
    ---@type conform.setupOpts
    opts = {
      default_format_opts = {
        timeout_ms = 3000, -- TODO: too long timeout?
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
      },
      ---@type table<string, conform.FormatterConfigOverride | fun(bufnr: integer): nil | conform.FormatterConfigOverride>
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
    },
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({
            formatters = { "injected" },
            timeout_ms = 3000,
          })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
  },
}
