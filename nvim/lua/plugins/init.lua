return {
  {
    "echasnovski/mini.nvim",
    version = "*",
    lazy = true,
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()

        return package.loaded["nvim-web-devicons"]
      end
    end,
    config = function()
      -- MINI.ICONS ------------------------------------------------------------

      require("mini.icons").setup({
        file = {
          [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
          [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
          [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
          [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
          [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
          [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
          ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
          ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
          ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
          ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
          ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
          ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
        },
        filetype = {
          dotenv = { glyph = "", hl = "MiniIconsYellow" },
          gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
        },
      })

      -- MINI.PAIRS ------------------------------------------------------------

      Snacks.toggle({
        name = "Mini Pairs",
        get = function()
          return not vim.g.minipairs_disable
        end,
        set = function(state)
          vim.g.minipairs_disable = not state
        end,
      }):map("<leader>up")

      local pairs = require("mini.pairs")
      local pairs_opts = {
        modes = { insert = true, command = true, terminal = false },
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_ts = { "string" },
        skip_unbalanced = true,
        markdown = true,
      }

      pairs.setup(pairs_opts)

      local open = pairs.open
      pairs.open = function(pair, neigh_pattern)
        if vim.fn.getcmdline() ~= "" then
          return open(pair, neigh_pattern)
        end

        local o, c = pair:sub(1, 1), pair:sub(2, 2)
        local line = vim.api.nvim_get_current_line()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local next = line:sub(cursor[2] + 1, cursor[2] + 1)
        local before = line:sub(1, cursor[2])

        if
          pairs_opts.markdown
          and o == "`"
          and vim.bo.filetype == "markdown"
          and before:match("^%s*``")
        then
          return "`\n```"
            .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
        end

        if
          pairs_opts.skip_next
          and next ~= ""
          and next:match(pairs_opts.skip_next)
        then
          return o
        end

        if pairs_opts.skip_ts and #pairs_opts.skip_ts > 0 then
          local ok, captures = pcall(
            vim.treesitter.get_captures_at_pos,
            0,
            cursor[1] - 1,
            math.max(cursor[2] - 1, 0)
          )

          for _, capture in ipairs(ok and captures or {}) do
            if vim.tbl_contains(pairs_opts.skip_ts, capture.capture) then
              return o
            end
          end
        end

        if pairs_opts.skip_unbalanced and next == c and c ~= o then
          local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
          local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")

          if count_close > count_open then
            return o
          end
        end

        return open(pair, neigh_pattern)
      end

      -- MINI.SURROUND ---------------------------------------------------------

      require("mini.surround").setup({
        mappings = {
          add = "gsa",
          delete = "gsd",
          find = "gsf",
          find_left = "gsF",
          highlight = "gsh",
          replace = "gsr",
          update_n_lines = "gsn",
        },
      })
    end,
  },
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "folke/snacks.nvim",
    version = "^2.22.0",
    priority = 1000,
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Toggle keymaps
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.inlay_hints():map("<leader>uh")

          local supermaven = require("supermaven-nvim.api")

          Snacks.toggle({
            name = "Supermaven",
            get = function()
              return supermaven.is_running()
            end,
            set = function(state)
              if state then
                supermaven.stop()
              else
                supermaven.stop()
              end
            end,
          }):map("<leader>us")
        end,
      })

      ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
      local progress = vim.defaulttable()
      vim.api.nvim_create_autocmd("LspProgress", {
        ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
          if not client or type(value) ~= "table" then
            return
          end
          local p = progress[client.id]

          for i = 1, #p + 1 do
            if i == #p + 1 or p[i].token == ev.data.params.token then
              p[i] = {
                token = ev.data.params.token,
                msg = ("[%3d%%] %s%s"):format(
                  value.kind == "end" and 100 or value.percentage or 100,
                  value.title or "",
                  value.message and (" **%s**"):format(value.message) or ""
                ),
                done = value.kind == "end",
              }
              break
            end
          end

          local msg = {} ---@type string[]
          progress[client.id] = vim.tbl_filter(function(v)
            return table.insert(msg, v.msg) or not v.done
          end, p)

          local spinner = {
            "⠋",
            "⠙",
            "⠹",
            "⠸",
            "⠼",
            "⠴",
            "⠦",
            "⠧",
            "⠇",
            "⠏",
          }
          vim.notify(table.concat(msg, "\n"), "info", {
            id = "lsp_progress",
            title = client.name,
            opts = function(notif)
              notif.icon = #progress[client.id] == 0 and " "
                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
            end,
          })
        end,
      })
    end,
    opts = {
      bigfile = { enabled = true },
      indent = { enabled = true },
      lazygit = {
        enabled = vim.g.lazygit_enabled,
      },
      notifier = {
        enabled = true,
        style = "minimal",
      },
      quickfile = { enabled = true },
    },
    keys = {
      {
        "<leader>n",
        function()
          if Snacks.config.picker and vim.g.finder == "snacks" then
            Snacks.picker.notifications()
          else
            Snacks.notifier.show_history()
          end
        end,
        desc = "Notification History",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
    },
  },
}
