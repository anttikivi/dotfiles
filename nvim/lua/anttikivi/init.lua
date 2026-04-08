local M = {}

function M.debounce(ms, fn)
    local timer = vim.uv.new_timer()

    return function(...)
        local argv = { ... }

        if timer == nil then
            vim.notify("error running `debounce`, timer is nil", vim.log.levels.ERROR)
            return
        end

        timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
        end)
    end
end

---@type table<(fun()), table<string, any>>
local memoize_cache = {}

---@generic T: fun()
---@param fn T
---@return T
function M.memoize(fn)
    return function(...)
        local key = vim.inspect({ ... })
        memoize_cache[fn] = memoize_cache[fn] or {}

        if memoize_cache[fn][key] == nil then
            memoize_cache[fn][key] = fn(...)
        end

        return memoize_cache[fn][key]
    end
end

return M
