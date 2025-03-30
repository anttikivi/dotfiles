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
        astro = { "prettier" },
        css = { "prettier" },
        go = { "goimports", "gofumpt" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
        php = { "php_cs_fixer" },
        sh = { "shfmt" },
        hcl = { "packer_fmt" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        yaml = { "prettier" },
        ["yaml.ansible"] = { "prettier" },
      },
      ---@type table<string, conform.FormatterConfigOverride | fun(bufnr: integer): nil | conform.FormatterConfigOverride>
      formatters = {
        injected = { options = { ignore_errors = true } },
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in
              ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false))
            do
              ---@diagnostic disable-next-line: undefined-field
              if line:find("<!%-%- toc %-%->") then
                return true
              end
              ---@diagnostic disable-next-line: missing-return
            end
          end,
        },
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))

            return #diag > 0
          end,
        },
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
