---@class util
local M = {}

---Create an autocommand group.
---@param name string
---@param opts? vim.api.keyset.create_augroup
---@return integer
function M.augroup(name, opts)
    opts = opts ~= nil and opts or {}
    opts.clear = opts.clear ~= nil and opts.clear or true
    return vim.api.nvim_create_augroup("anttikivi_" .. name, opts)
end

---Check whether Neovim is currently running on Windows.
---@return boolean
function M.is_win()
    return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@return string
function M.norm(path)
    if path:sub(1, 1) == "~" then
        local home = vim.uv.os_homedir()
        if home:sub(-1) == "\\" or home:sub(-1) == "/" then
            home = home:sub(1, -2)
        end
        path = home .. path:sub(2)
    end
    path = path:gsub("\\", "/"):gsub("/+", "/")
    return path:sub(-1) == "/" and path:sub(1, -2) or path
end

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
