local cmp_util = require("util.cmp")
local icons = require("config.icons")

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
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
}
