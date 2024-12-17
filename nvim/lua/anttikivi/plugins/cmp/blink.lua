-- This module is based on LazyVim/LazyVim, licensed under Apache-2.0.

return {
  {
    "saghen/blink.cmp",
    version = not AK.config.blink_follow_main and "*",
    build = AK.config.blink_follow_main and "cargo build --release",
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.compat",
      "sources.default",
    },
    dependencies = {
      "rafamadriz/friendly-snippets",
      -- add blink.compat to dependencies
      {
        "saghen/blink.compat",
        optional = true, -- TODO: make optional so it's only enabled if any extras need it
        opts = {},
        version = not AK.config.blink_follow_main and "*",
      },
    },
    event = "InsertEnter",
    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups.
        -- Useful for when your theme doesn't support blink.cmp. Will be removed
        -- in a future release, assuming themes add support
        use_nvim_cmp_as_default = false,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'.
        -- Adjusts spacing to ensure icons are aligned.
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          -- experimental auto-brackets support
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
          enabled = AK.config.ai_cmp,
        },
      },

      -- experimental signature help support
      -- signature = { enabled = true },

      sources = {
        -- Adding any nvim-cmp sources here will enable them with blink.compat.
        compat = {},
        default = { "lsp", "path", "snippets", "buffer" },
        cmdline = {},
      },

      keymap = {
        preset = "default",
        -- ["<C-y>"] = { "select_and_accept" },
      },
    },
    ---@param opts blink.cmp.Config | { sources: { compat: string[] } }
    config = function(_, opts)
      -- Setup compat sources.
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

      -- Add ai_accept to <Tab> key.
      if not opts.keymap["<Tab>"] then
        if opts.keymap.preset == "super-tab" then -- super-tab
          opts.keymap["<Tab>"] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            AK.cmp.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        else -- other presets
          opts.keymap["<Tab>"] = {
            AK.cmp.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        end
      end

      ---  NOTE: compat with latest version. Currenlty 0.7.6
      if not AK.config.blink_follow_main then
        ---@diagnostic disable-next-line: inject-field
        opts.sources.completion = opts.sources.completion or {}
        opts.sources.completion.enabled_providers = enabled
        if vim.tbl_get(opts, "completion", "menu", "draw", "treesitter") then
          ---@diagnostic disable-next-line: assign-type-mismatch
          opts.completion.menu.draw.treesitter = true
        end
      end

      -- Unset custom prop to pass blink.cmp validation
      opts.sources.compat = nil

      -- check if we need to override symbol kinds
      for _, provider in pairs(opts.sources.providers or {}) do
        ---@cast provider blink.cmp.SourceProviderConfig|{kind?:string}
        if provider.kind then
          local CompletionItemKind =
            require("blink.cmp.types").CompletionItemKind
          local kind_idx = #CompletionItemKind + 1

          CompletionItemKind[kind_idx] = provider.kind
          ---@diagnostic disable-next-line: no-unknown
          CompletionItemKind[provider.kind] = kind_idx

          ---@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
          local transform_items = provider.transform_items
          ---@param ctx blink.cmp.Context
          ---@param items blink.cmp.CompletionItem[]
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = kind_idx or item.kind
            end
            return items
          end

          -- Unset custom prop to pass blink.cmp validation
          provider.kind = nil
        end
      end

      require("blink.cmp").setup(opts)
    end,
  },

  -- Add icons.
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.appearance = opts.appearance or {}
      opts.appearance.kind_icons = vim.tbl_extend("keep", {
        Color = "██", -- Use a block instead of icon for color items to make swatches more usable.
      }, AK.config.icons.kinds)
    end,
  },

  -- lazydev.nvim support
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- Add lazydev to the completion provider.
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
          },
        },
      },
    },
  },

  -- Catppuccin support
  {
    "catppuccin",
    optional = true,
    opts = {
      integrations = { blink_cmp = true },
    },
  },
}
