---@class dot.util
local M = {}

local cache = {} ---@type table<(fun()), table<string, any>>

---@param t table<string, any>
function M.keys(t)
    local result = {}

    for k in pairs(t) do
        result[#result + 1] = k
    end

    return result
end

---@generic T: fun()
---@param fn T
---@return T
function M.memoize(fn)
    return function(...)
        local key = vim.inspect({ ... })
        cache[fn] = cache[fn] or {}

        if cache[fn][key] == nil then
            cache[fn][key] = fn(...)
        end

        return cache[fn][key]
    end
end

return M
