local M = {}

---@class anttikivi.Root
---@field paths string[]
---@field spec anttikivi.RootSpec

---@alias anttikivi.RootFn fun(buf: number): (string | string[])
---@alias anttikivi.RootSpec string | string[] | anttikivi.RootFn

---@return string?
local function norm(path)
    if path:sub(1, 1) == "~" then
        local home = vim.uv.os_homedir()
        if home == nil then
            vim.notify("failed to get the user's home directory", vim.log.levels.ERROR)
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

local function realpath(path)
    if path == "" or path == nil then
        return nil
    end

    path = vim.uv.fs_realpath(path) or path

    return norm(path)
end

local function bufpath(buf)
    return realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

local root_detectors = {}

function root_detectors.cwd()
    return { vim.uv.cwd() }
end

function root_detectors.lsp(buf)
    local bufp = bufpath(buf)

    if not bufp then
        return {}
    end

    local roots = {} ---@type string[]
    local clients = require("anttikivi.lsp").get_lsp_clients({ bufnr = buf })
    clients = vim.tbl_filter(function(client)
        return not vim.tbl_contains(vim.g.root_lsp_ignore or {}, client.name)
    end, clients)

    for _, client in pairs(clients) do
        local workspace = client.config.workspace_folders

        for _, ws in pairs(workspace or {}) do
            roots[#roots + 1] = vim.uri_to_fname(ws.uri)
        end

        if client.root_dir then
            roots[#roots + 1] = client.root_dir
        end
    end

    return vim.tbl_filter(function(path)
        path = norm(path --[[@as string]])

        return path and bufp:find(path, 1, true) == 1 or false
    end, roots)
end

---@param patterns string[] | string
function root_detectors.pattern(buf, patterns)
    patterns = type(patterns) == "string" and { patterns } or patterns

    ---@cast patterns string[]

    local path = bufpath(buf) or vim.uv.cwd()
    local pattern = vim.fs.find(function(name)
        for _, p in ipairs(patterns) do
            if name == p then
                return true
            end

            if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
                return true
            end
        end

        return false
    end, { path = path, upward = true })[1]

    return pattern and { vim.fs.dirname(pattern) } or {}
end

---@param spec anttikivi.RootSpec
---@return anttikivi.RootFn
local function resolve_root(spec)
    if root_detectors[spec] then
        return root_detectors[spec]
    elseif type(spec) == "function" then
        return spec
    end

    return function(buf)
        return root_detectors.pattern(buf, spec)
    end
end

---@param opts? { buf?: number, spec?: anttikivi.RootSpec[], all?: boolean }
local function detect_root(opts)
    opts = opts or {}
    opts.spec = opts.spec or vim.g.root_spec
    opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

    local ret = {} ---@type anttikivi.Root[]

    for _, spec in ipairs(opts.spec) do
        local paths = resolve_root(spec)(opts.buf)
        paths = paths or {}
        paths = type(paths) == "table" and paths or { paths }
        local roots = {} ---@type string[]

        for _, p in ipairs(paths) do
            local pp = realpath(p)

            if pp and not vim.tbl_contains(roots, pp) then
                roots[#roots + 1] = pp
            end
        end

        table.sort(roots, function(a, b)
            return #a > #b
        end)

        if #roots > 0 then
            ret[#ret + 1] = { spec = spec, paths = roots }

            if opts.all == false then
                break
            end
        end
    end

    return ret
end

---@type table<number, string>
local root_cache = {}

---@param opts? { normalize?: boolean, buf?: number }
---@return string
function M.get(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    local result = root_cache[buf]

    if not result then
        local roots = detect_root({ all = false, buf = buf })
        result = roots[1] and roots[1].paths[1] or vim.uv.cwd()
        root_cache[buf] = result
    end

    if opts and opts.normalize then
        return result
    end

    return vim.uv.os_uname().sysname:find("Windows") ~= nil and result:gsub("/", "\\") or result
end

function M.init()
    vim.api.nvim_create_augroup("root_cache", { clear = true })
    vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
        group = "root_cache",
        callback = function(event)
            root_cache[event.buf] = nil
        end,
    })

    vim.api.nvim_create_user_command("Root", function()
        local spec = vim.g.root_spec
        local roots = detect_root({ all = true })
        local lines = {} ---@type string[]
        local first = true

        for _, root in ipairs(roots) do
            for _, path in ipairs(root.paths) do
                lines[#lines + 1] = string.format(
                    "- [%s] `%s` **(%s)**",
                    first and "x" or " ",
                    path,
                    ---@diagnostic disable-next-line: param-type-mismatch
                    type(root.spec) == "table" and table.concat(root.spec, ", ") or root.spec
                )
                first = false
            end
        end

        lines[#lines + 1] = "```lua"
        lines[#lines + 1] = "vim.g.root_spec = " .. vim.inspect(spec)
        lines[#lines + 1] = "```"

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end, { desc = "Roots for the current buffer" })
end

return M
