local LazyUtil = require("lazy.core.util")

local M = {}

---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
function M.get_pkg_path(pkg, path, opts)
  pcall(require, "mason")

  local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  opts = opts or {}
  opts.warn = opts.warn == nil and true or opts.warn
  path = path or ""
  local ret = root .. "/packages/" .. pkg .. "/" .. path

  if
    opts.warn
    and not vim.loop.fs_stat(ret)
    and not require("lazy.core.config").headless()
  then
    LazyUtil.warn(
      ("Mason package path not found for **%s**:\n- `%s`\nYou may need to force update the package."):format(
        pkg,
        path
      )
    )
  end

  return ret
end

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

return M
