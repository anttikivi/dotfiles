local LazyUtil = require("lazy.core.util")

---@class format
---@overload fun(opts?: { force?: boolean })
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.format(...)
  end,
})

---@class Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

M.formatters = {} ---@type Formatter[]

---@param formatter Formatter
function M.register(formatter)
  M.formatters[#M.formatters + 1] = formatter

  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
end

---@param buf? number
function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local gaf = vim.g.autoformat
  local baf = vim.b[buf].autoformat

  if baf ~= nil then
    return baf
  end

  return gaf == nil or gaf
end

---@param buf? number
function M.info(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local gaf = vim.g.autoformat == nil or vim.g.autoformat
  local baf = vim.b[buf].autoformat
  local enabled = M.enabled(buf)
  local lines = {
    "# Status",
    ("- [%s] global **%s**"):format(
      gaf and "x" or " ",
      gaf and "enabled" or "disabled"
    ),
    ("- [%s] buffer **%s**"):format(
      enabled and "x" or " ",
      baf == nil and "inherit" or baf and "enabled" or "disabled"
    ),
  }
  local have = false

  for _, formatter in ipairs(M.resolve(buf)) do
    if #formatter.resolved > 0 then
      have = true
      lines[#lines + 1] = "\n# "
        .. formatter.name
        .. (formatter.active and " ***(active)***" or "")
      for _, line in ipairs(formatter.resolved) do
        lines[#lines + 1] = ("- [%s] **%s**"):format(
          formatter.active and "x" or " ",
          line
        )
      end
    end
  end

  if not have then
    lines[#lines + 1] = "\n***No formatters available for this buffer.***"
  end

  LazyUtil[enabled and "info" or "warn"](
    table.concat(lines, "\n"),
    { title = "util.format (" .. (enabled and "enabled" or "disabled") .. ")" }
  )
end

---@param buf? number
---@return (Formatter | { active: boolean, resolved: string[] })[]
function M.resolve(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local have_primary = false

  ---@param formatter Formatter
  return vim.tbl_map(function(formatter)
    local sources = formatter.sources(buf)
    local active = #sources > 0 and (not formatter.primary or not have_primary)
    have_primary = have_primary or (active and formatter.primary) or false

    return setmetatable({
      active = active,
      resolved = sources,
    }, { __index = formatter })
  end, M.formatters)
end

---@param opts? { force?: boolean, buf?: number }
function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  if not ((opts and opts.force) or M.enabled(buf)) then
    return
  end

  local done = false

  for _, formatter in ipairs(M.resolve(buf)) do
    if formatter.active then
      done = true
      LazyUtil.try(function()
        return formatter.format(buf)
      end, { msg = "Formatter `" .. formatter.name .. "` failed" })
    end
  end

  if not done and opts and opts.force then
    LazyUtil.warn("No formatter available", { title = "util.format" })
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("util.format", {}),
    callback = function(event)
      M.format({ buf = event.buf })
    end,
  })
  vim.api.nvim_create_user_command("Format", function()
    M.format({ force = true })
  end, { desc = "Format selection or buffer" })
  vim.api.nvim_create_user_command("FormatInfo", function()
    M.info()
  end, { desc = "Show info about the formatters for the current buffer" })
end

function M.formatexpr()
  if require("util.plugin").has("conform.nvim") then
    return require("conform").formatexpr()
  end

  return vim.lsp.formatexpr({ timeout_ms = 3000 })
end

return M
