local prettier_supported = {
  "astro",
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
  "yaml.ansible",
}

---@alias ConformCtx {buf: number, filename: string, dirname: string}

--- Checks if a Prettier config file exists for the given context
---@param ctx ConformCtx
local function has_prettier_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })

  return vim.v.shell_error == 0
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
---@param ctx ConformCtx
local function has_prettier_parser(ctx)
  local ft = vim.bo[ctx.buf].filetype --[[@as string]]
  if vim.tbl_contains(prettier_supported, ft) then
    return true
  end

  local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })

  ---@type boolean, string?
  local ok, parser = pcall(function()
    return vim.fn.json_decode(ret).inferredParser
  end)

  return ok and parser and parser ~= vim.NIL
end

has_prettier_config = require("util").memoize(has_prettier_config)
has_prettier_parser = require("util").memoize(has_prettier_parser)

return {
  {
    "stevearc/conform.nvim",
    version = "^9.0.0",
    dependencies = { "williamboman/mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
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
        blade = { "blade-formatter" },
        go = { "goimports", "gofumpt" },
        lua = { "stylua" },
        php = { "pint", "php_cs_fixer" },
        sh = { "shfmt" },
        hcl = { "packer_fmt" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
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

  -- Prettier configuration
  {
    "stevearc/conform.nvim",
    ---@param opts conform.setupOpts
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(prettier_supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(opts.formatters_by_ft[ft], "prettier")
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = {
        condition = function(_, ctx)
          return has_prettier_parser(ctx)
            and (
              vim.g.prettier_needs_config ~= true or has_prettier_config(ctx)
            )
        end,
        prepend_args = { "--prose-wrap", "always" },
      }
    end,
  },
}
