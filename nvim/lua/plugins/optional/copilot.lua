return {
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      require("util.cmp").actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          require("util").create_undo()
          require("copilot.suggestion").accept()

          return true
        end
      end

      return {
        suggestion = {
          enabled = not vim.g.ai_cmp,
          auto_trigger = true,
          hide_during_completion = vim.g.ai_cmp,
          keymap = {
            accept = false, -- Handled by the completion engine
            next = "<M-]>",
            prev = "<M-[>",
          },
        },
        panel = { enabled = false },
        filetypes = {
          help = true,
          markdown = true,
          yaml = true,
        },
        -- copilot_model = "claude-3.5-sonnet",
        copilot_model = "gpt-4o-copilot",
      }
    end,
    build = ":Copilot auth",
    event = "BufReadPost",
    cmd = "Copilot",
  },
  vim.g.ai_cmp
      and {
        {
          "hrsh7th/nvim-cmp",
          dependencies = {
            {
              "zbirenbaum/copilot-cmp",
              config = function(_, opts)
                local copilot_cmp = require("copilot_cmp")

                copilot_cmp.setup(opts)
                require("util.lsp").on_attach(function()
                  copilot_cmp._on_insert_enter({})
                end, "copilot")
              end,
              opts = {},
              specs = {
                {
                  "hrsh7th/nvim-cmp",
                  ---@param opts cmp.ConfigSchema
                  opts = function(_, opts)
                    table.insert(opts.sources, 1, {
                      name = "copilot",
                      group_index = 1,
                      priority = 100,
                    })
                  end,
                  optional = true,
                },
              },
            },
          },
          optional = true,
        },
        {
          "saghen/blink.cmp",
          dependencies = { "giuxtaposition/blink-cmp-copilot" },
          opts = {
            sources = {
              default = { "copilot" },
              providers = {
                copilot = {
                  name = "copilot",
                  module = "blink-cmp-copilot",
                  kind = "Copilot",
                  score_offset = 100,
                  async = true,
                },
              },
            },
          },
          optional = true,
        },
      }
    or nil,
}
