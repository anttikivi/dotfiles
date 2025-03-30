local cmp_util = require("util.cmp")
local icons = require("config.icons")

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    enabled = vim.g.cmp_engine == "blink",
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.compat",
      "sources.default",
    },
    opts = function()
      ---@module "blink.cmp"
      ---@type blink.cmp.Config
      local opts = {
        snippets = {
          expand = function(snippet)
            return cmp_util.expand(snippet)
          end,
        },
        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = "mono",
        },
        completion = {
          accept = {
            -- Experimental auto-brackets support
            auto_brackets = {
              enabled = true,
            },
          },
          menu = {
            draw = {
              treesitter = { "lsp" },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
          },
          ghost_text = {
            enabled = vim.g.ai_cmp,
          },
        },
        -- Experimental signature help support
        signature = {
          enabled = false,
        },
        sources = {
          compat = {},
          default = { "lsp", "path", "snippets", "buffer", "lazydev" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
          },
        },
        cmdline = {
          enabled = false,
        },
        keymap = {
          preset = "default",
        },
      }

      opts.appearance = opts.appearance or {}
      opts.appearance.kind_icons =
        vim.tbl_extend("force", opts.appearance.kind_icons or {}, icons.kinds)

      return opts
    end,
    ---@param opts blink.cmp.Config | { sources: { compat: string[] } }
    config = function(_, opts)
      local enabled = opts.sources.default

      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )

        if
          type(enabled) == "table" and not vim.tbl_contains(enabled, source)
        then
          table.insert(enabled, source)
        end
      end

      if not opts.keymap["<Tab>"] then
        if opts.keymap.preset == "super-tab" then
          opts.keymap["<Tab>"] = {
            require("blink.cmp.keymap.presets")["super-tab"]["<Tab>"][1],
            cmp_util.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        else
          opts.keymap["<Tab>"] = {
            cmp_util.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        end
      end

      opts.sources.compat = nil

      for _, provider in pairs(opts.sources.providers or {}) do
        ---@cast provider blink.cmp.SourceProviderConfig |{ kind?: string }
        if provider.kind then
          local CompletionItemKind =
            require("blink.cmp.types").CompletionItemKind
          local kind_idx = #CompletionItemKind + 1

          CompletionItemKind[kind_idx] = provider.kind
          CompletionItemKind[provider.kind] = kind_idx

          ---@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
          local transform_items = provider.transform_items
          ---@param ctx blink.cmp.Context
          ---@param items blink.cmp.CompletionItem[]
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = kind_idx or item.kind
              item.kind_icon = icons.kinds[item.kind_name]
                or item.kind_icon
                or nil
            end

            return items
          end

          provider.kind = nil
        end
      end

      require("blink.cmp").setup(opts)
    end,
    build = "cargo build --release",
    event = "InsertEnter",
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
    },
    enabled = vim.g.cmp_engine == "nvim-cmp",
    opts = function()
      vim.api.nvim_set_hl(
        0,
        "CmpGhostText",
        { link = "Comment", default = true }
      )

      local cmp = require("cmp")
      local defaults = require("cmp.config.default")()
      local auto_select = true

      return {
        auto_brackets = { "python" },
        completion = {
          completeopt = "menu,menuone,noinsert"
            .. (auto_select and "" or ",noselect"),
        },
        preselect = auto_select and cmp.PreselectMode.Item
          or cmp.PreselectMode.None,
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-n>"] = cmp.mapping.select_next_item({
            behavior = cmp.SelectBehavior.Insert,
          }),
          ["<C-p>"] = cmp.mapping.select_prev_item({
            behavior = cmp.SelectBehavior.Insert,
          }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-y>"] = cmp_util.confirm({ select = true }),
          ["<C-CR>"] = function(fallback)
            cmp.abort()
            fallback()
          end,
          ["<tab>"] = function(fallback)
            return cmp_util.map({ "snippet_forward", "ai_accept" }, fallback)()
          end,
        }),
        sources = cmp.config.sources({
          { name = "lazydev" },
          { name = "nvim_lsp" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = function(_, item)
            if icons[item.kind] then
              item.kind = icons.kinds[item.kind] .. item.kind
            end

            local widths = {
              abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 40,
              menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
            }

            for key, width in pairs(widths) do
              if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
                item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
              end
            end

            return item
          end,
        },
        experimental = {
          -- only show ghost text when we show ai completions
          ghost_text = vim.g.ai_cmp and {
            hl_group = "CmpGhostText",
          } or false,
        },
        sorting = defaults.sorting,
      }
    end,
    config = function(_, opts)
      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end

      local parse = require("cmp.utils.snippet").parse

      ---@diagnostic disable-next-line: duplicate-set-field
      require("cmp.utils.snippet").parse = function(input)
        local ok, ret = pcall(parse, input)
        if ok then
          return ret
        end
        return cmp_util.snippet_preview(input)
      end

      local cmp = require("cmp")

      cmp.setup(opts)
      cmp.event:on("confirm_done", function(event)
        if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
          local Kind = cmp.lsp.CompletionItemKind
          local item = event.entry:get_completion_item()

          if vim.tbl_contains({ Kind.Function, Kind.Method }, item.kind) then
            local cursor = vim.api.nvim_win_get_cursor(0)
            local prev_char = vim.api.nvim_buf_get_text(
              0,
              cursor[1] - 1,
              cursor[2],
              cursor[1] - 1,
              cursor[2] + 1,
              {}
            )[1]

            if prev_char ~= "(" and prev_char ~= ")" then
              local keys =
                vim.api.nvim_replace_termcodes("()<left>", false, false, true)
              vim.api.nvim_feedkeys(keys, "i", true)
            end
          end
        end
      end)
      cmp.event:on("menu_opened", function(event)
        local Kind = cmp.lsp.CompletionItemKind
        local entries = event.window:get_entries()

        for _, entry in ipairs(entries) do
          if entry:get_kind() == Kind.Snippet then
            local item = entry:get_completion_item()
            if not item.documentation and item.insertText then
              item.documentation = {
                kind = cmp.lsp.MarkupKind.Markdown,
                value = string.format(
                  "```%s\n%s\n```",
                  vim.bo.filetype,
                  cmp_util.snippet_preview(item.insertText)
                ),
              }
            end
          end
        end
      end)
    end,
    event = "InsertEnter",
  },
  {
    "folke/lazydev.nvim",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
    cmd = "LazyDev",
    ft = "lua",
  },
}
