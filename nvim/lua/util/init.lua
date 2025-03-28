local M = {}

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

return M
