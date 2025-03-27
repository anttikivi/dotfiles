local M = {}

---@alias Action fun(): boolean?
---@type table<string, Action>
M.actions = {
  -- Native snippets
  snippet_forward = function()
    if vim.snippet.active({ direction = 1 }) then
      vim.schedule(function()
        vim.snippet.jump(1)
      end)
      return true
    end
  end,
  snippet_stop = function()
    if vim.snippet then
      vim.snippet.stop()
    end
  end,
}

---@param actions string[]
---@param fallback? string | fun()
function M.map(actions, fallback)
  return function()
    for _, name in ipairs(actions) do
      if M.actions[name] then
        local ret = M.actions[name]()
        if ret then
          return true
        end
      end
    end

    return type(fallback) == "function" and fallback() or fallback
  end
end

-- This is a better implementation of `cmp.confirm`:
--  * check if the completion menu is visible without waiting for running sources
--  * create an undo point before confirming
-- This function is both faster and more reliable.
---@param opts? { select: boolean, behavior: cmp.ConfirmBehavior }
function M.confirm(opts)
  local cmp = require("cmp")
  opts = vim.tbl_extend("force", {
    select = true,
    behavior = cmp.ConfirmBehavior.Insert,
  }, opts or {})

  return function(fallback)
    if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
      -- Create undo.
      if vim.api.nvim_get_mode().mode == "i" then
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<c-G>u", true, true, true),
          "n",
          false
        )
      end

      if cmp.confirm(opts) then
        return
      end
    end

    return fallback()
  end
end

-- This function resolves nested placeholders in a snippet.
---@param snippet string
---@return string
function M.snippet_preview(snippet)
  local ok, parsed = pcall(function()
    return vim.lsp._snippet_grammar.parse(snippet)
  end)

  return ok and tostring(parsed)
    or M.snippet_replace(snippet, function(placeholder)
      return M.snippet_preview(placeholder.text)
    end):gsub("%$0", "")
end

---@alias Placeholder { n: number, text: string }

---@param snippet string
---@param fn fun(placeholder: Placeholder): string
---@return string
function M.snippet_replace(snippet, fn)
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    return n and fn({ n = n, text = name }) or m
  end) or snippet
end

return M
