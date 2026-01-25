---@class dot.util
local M = {}

local cache = {} ---@type table<(fun()), table<string, any>>

-- Create an autocommand group.
---@param name string
---@param opts? vim.api.keyset.create_augroup
---@return integer
function M.augroup(name, opts)
    opts = opts ~= nil and opts or {}
    opts.clear = opts.clear ~= nil and opts.clear or true
    return vim.api.nvim_create_augroup("dot_" .. name, opts)
end

---@generic T
---@param haystack T[]
---@param needle T
---@return boolean
function M.contains(haystack, needle)
    if type(haystack) == "nil" then
        return false
    end

    for _, v in ipairs(haystack) do
        if v == needle then
            return true
        end
    end
    return false
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
    if vim.api.nvim_get_mode().mode == "i" then
        vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
    end
end

---Check whether Neovim is currently running on Windows.
---@return boolean
function M.is_win()
    return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

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

---@param path string
---@return string?
function M.norm(path)
    if path:sub(1, 1) == "~" then
        local home = vim.uv.os_homedir()
        if home == nil then
            vim.notify("Failed to get the user's home directory", vim.log.levels.ERROR)
            return nil
        end

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

return M
