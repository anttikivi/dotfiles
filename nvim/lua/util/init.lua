---@class Util
local M = {}

---@generic R
---@param fn fun(): R?
---@param opts? string | { msg: string, on_error: fun(msg) }
---@return R
function M.try(fn, opts)
    opts = type(opts) == "string" and { msg = opts } or opts or {}
    local msg = opts.msg
    -- error handler
    local error_handler = function(err)
        msg = (msg and (msg .. "\n\n") or "") .. err
        if opts.on_error then
            opts.on_error(msg)
        else
            vim.schedule(function()
                vim.notify(msg, vim.log.levels.ERROR)
            end)
        end
        return err
    end

    ---@type boolean, any
    local ok, result = xpcall(fn, error_handler)
    return ok and result or nil
end

local cache = {} ---@type table<(fun()), table<string, any>>

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
