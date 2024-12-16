local LazyUtil = require("lazy.core.util")

---@class anttikivi.util: LazyUtilCore
---@field config AKConfig
---@field format anttikivi.util.format
---@field lsp anttikivi.util.lsp
---@field plugin anttikivi.util.plugin
---@field root anttikivi.util.root
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end
    t[k] = require("anttikivi.util." .. k)
    return t[k]
  end,
})

return M
