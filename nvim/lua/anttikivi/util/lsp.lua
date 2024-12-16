-- This module is based on LazyVim/LazyVim, licensed under Apache-2.0.

---@class anttikivi.util.lsp
local M = {}

---@alias lsp.Client.filter { id?: number, bufnr?: number, name?: string, method?: string, filter?: fun(client: vim.lsp.Client): boolean }

---@param opts? lsp.Client.filter
function M.get_clients(opts)
  local ret = {} ---@type vim.lsp.Client[]
  if vim.lsp.get_clients then
    ret = vim.lsp.get_clients(opts)
  else
    ---@diagnostic disable-next-line: deprecated
    ret = vim.lsp.get_active_clients(opts)
    if opts and opts.method then
      ---@param client vim.lsp.Client
      ret = vim.tbl_filter(function(client)
        ---@diagnostic disable-next-line: param-type-mismatch
        return client.supports_method(opts.method, { bufnr = opts.bufnr })
      end, ret)
    end
  end
  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

return M
