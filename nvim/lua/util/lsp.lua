local LazyUtil = require("lazy.core.util")

---@class util.lsp
local M = {}

---@class util.lsp.Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

---@param filter? util.lsp.Filter
---@return vim.lsp.Client[]
function M.get_clients(filter)
  local clients = vim.lsp.get_clients(filter)
  return filter and filter.filter and vim.tbl_filter(filter.filter, clients)
    or clients
end

-- Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param on_attach fun(client: vim.lsp.Client, buf: integer)
---@param name? string
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type integer
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        -- TODO: Modify if the function passed as a parameter should return a
        -- value.
        on_attach(client, buffer)
      end
    end,
  })
end

-- Register a function to be run with an autocommand when a language server changes its capabilities dynamically.
---@param fn fun(client: vim.lsp.Client, buffer: integer): boolean?
---@param opts? { group?: integer }
function M.on_dynamic_capability(fn, opts)
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspDynamicCapability",
    group = opts and opts.group or nil,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type integer

      if client then
        return fn(client, buffer)
      end
    end,
  })
end

---@param method string
---@param fn fun(client: vim.lsp.Client, buffer: integer)
function M.on_supports_method(method, fn)
  M._supports_method[method] = M._supports_method[method]
    or setmetatable({}, { __mode = "k" })

  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type integer

      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

-- Run general setup for the LSP client.
--
-- The function sets up an override for the capability-registering function of
-- the LSP client and registers functions that check the language server methods
-- to be run when a server attaches to a buffer or changes its capabilities
-- dynamically.
function M.setup()
  local register_capability = vim.lsp.handlers["client/registerCapability"]

  vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
    local ret = register_capability(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)

    if client then
      for buffer in pairs(client.attached_buffers) do
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
          data = { client_id = client.id, buffer = buffer },
        })
      end
    end

    return ret
  end

  M.on_attach(M._check_methods)
  M.on_dynamic_capability(M._check_methods)
end

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

---@param client vim.lsp.Client
---@param buffer integer
function M._check_methods(client, buffer)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end

  if not vim.bo[buffer].buflisted then
    return
  end

  if vim.bo[buffer].buftype == "nofile" then
    return
  end

  for method, clients in pairs(M._supports_method) do
    clients[client] = clients[client] or {}
    if not clients[client][buffer] then
      if client:supports_method(method, buffer) then
        clients[client][buffer] = true

        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspSupportsMethod",
          data = { client_id = client.id, buffer = buffer, method = method },
        })
      end
    end
  end
end

---@param opts? Formatter | { filter?: (string | util.lsp.Filter) }
function M.formatter(opts)
  opts = opts or {}
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  ---@cast filter util.lsp.Filter
  ---@type Formatter
  local ret = {
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
      M.format(LazyUtil.merge({}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = M.get_clients(LazyUtil.merge({}, filter, { bufnr = buf }))
      ---@param client vim.lsp.Client
      local ret = vim.tbl_filter(function(client)
        return client:supports_method("textDocument/formatting")
          or client:supports_method("textDocument/rangeFormatting")
      end, clients)
      ---@param client vim.lsp.Client
      return vim.tbl_map(function(client)
        return client.name
      end, ret)
    end,
  }

  return LazyUtil.merge(ret, opts) --[[@as Formatter]]
end

---@alias util.lsp.Format { timeout_ms?: number, format_options?: table } | util.lsp.Filter

---@param opts? util.lsp.Format
function M.format(opts)
  opts = vim.tbl_deep_extend(
    "force",
    {},
    opts or {},
    require("util.plugin").opts("nvim-lspconfig").format or {},
    require("util.plugin").opts("conform.nvim").format or {}
  )
  local ok, conform = pcall(require, "conform")

  if ok then
    opts.formatters = {}
    conform.format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
function M.execute(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }

  if opts.open then
    require("trouble").open({
      mode = "lsp_command",
      params = params,
    })
  else
    return vim.lsp.buf_request(
      0,
      "workspace/executeCommand",
      params,
      opts.handler
    )
  end
end

return M
