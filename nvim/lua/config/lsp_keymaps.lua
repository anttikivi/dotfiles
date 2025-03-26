local lsp_util = require("util.lsp")

local M = {}

---@module 'lazy'
---@alias LspKeysSpec LazyKeysSpec | { has?: string | string[], cond?: fun(): boolean }
---@alias LspKeys LazyKeys | { has?: string | string[], cond?: fun(): boolean }

---@type LspKeysSpec[] | nil
M._keys = nil

---@return LspKeysSpec[]
function M.get()
  if M._keys then
    return M._keys
  end

  M._keys = {
    {
      "gd",
      vim.lsp.buf.definition,
      desc = "Goto definition",
      has = "definition",
    },
    { "gr", vim.lsp.buf.references, desc = "Goto references", nowait = true },
    { "gI", vim.lsp.buf.implementation, desc = "Goto implementation" },
    { "gy", vim.lsp.buf.type_definition, desc = "Goto type definition" },
    { "gD", vim.lsp.buf.declaration, desc = "Goto declaration" },
    {
      "K",
      function()
        return vim.lsp.buf.hover()
      end,
      desc = "Hover",
    },
    {
      "gK",
      function()
        return vim.lsp.buf.signature_help()
      end,
      desc = "Signature help",
      has = "signatureHelp",
    },
    {
      "<c-k>",
      function()
        return vim.lsp.buf.signature_help()
      end,
      mode = "i",
      desc = "Signature help",
      has = "signatureHelp",
    },
    {
      "<leader>ca",
      vim.lsp.buf.code_action,
      desc = "Code actions",
      mode = { "n", "v" },
      has = "codeAction",
    },
  }

  return M._keys
end

---@param buffer? integer
---@param method string | string[]
---@return boolean
function M.has(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end

    return false
  end

  method = method:find("/") and method or "textDocument/" .. method

  local clients = lsp_util.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      return true
    end
  end

  return false
end

---@param buffer? integer
---@return LspKeys[]
function M.resolve(buffer)
  local Keys = require("lazy.core.handler.keys")
  if not Keys.resolve then
    return {}
  end

  local spec = vim.tbl_extend("force", {}, M.get())
  local opts = require("util.plugin").opts("nvim-lspconfig")
  local clients = lsp_util.get_clients({ bufnr = buffer })

  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys
      or {}
    vim.list_extend(spec, maps)
  end

  return Keys.resolve(spec)
end

---@param buffer? integer
function M.on_attach(_, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    local has = not keys.has or M.has(buffer, keys.has)
    local cond = not (
      keys.cond == false
      or ((type(keys.cond) == "function") and not keys.cond())
    )

    if has and cond then
      local opts = Keys.opts(keys)

      opts.cond = nil
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer

      vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
    end
  end
end

return M
