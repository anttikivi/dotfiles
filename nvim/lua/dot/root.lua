local util = require("dot.util")

---@class Root
---@field paths string[]
---@field spec RootSpec

---@alias RootFn fun(buf: number): (string | string[])
---@alias RootSpec string | string[] | RootFn

---@class dot.root
---@overload fun(): string
local M = setmetatable({}, {
    __call = function(m, ...)
        return m.get(...)
    end,
})

---@type RootSpec[]
local root_spec = { "lsp", { ".git" }, "cwd" }

local function realpath(path)
    if path == "" or path == nil then
        return nil
    end

    path = vim.uv.fs_realpath(path) or path

    return util.norm(path)
end

local function bufpath(buf)
    return realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

local detectors = {}

function detectors.cwd()
    return { vim.uv.cwd() }
end

function detectors.lsp(buf)
    local bufp = bufpath(buf)

    if not bufp then
        return {}
    end

    local roots = {} ---@type string[]
    local clients = require("dot.lsp").get_clients({ bufnr = buf })
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
        path = util.norm(path --[[@as string]])

        return path and bufp:find(path, 1, true) == 1 or false
    end, roots)
end

---@param patterns string[] | string
function detectors.pattern(buf, patterns)
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

---@param spec RootSpec
---@return RootFn
local function resolve(spec)
    if detectors[spec] then
        return detectors[spec]
    elseif type(spec) == "function" then
        return spec
    end

    return function(buf)
        return detectors.pattern(buf, spec)
    end
end

---@param opts? { buf?: number, spec?: RootSpec[], all?: boolean }
local function detect(opts)
    opts = opts or {}
    opts.spec = opts.spec or type(vim.g.root_spec) == "table" and vim.g.root_spec or root_spec
    opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

    local ret = {} ---@type Root[]

    for _, spec in ipairs(opts.spec) do
        local paths = resolve(spec)(opts.buf)
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

local function info()
    local spec = type(vim.g.root_spec) == "table" and vim.g.root_spec or root_spec
    local roots = detect({ all = true })
    local lines = {} ---@type string[]
    local first = true

    for _, root in ipairs(roots) do
        for _, path in ipairs(root.paths) do
            lines[#lines + 1] = ("- [%s] `%s` **(%s)**"):format(
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

    return roots[1] and roots[1].paths[1] or vim.uv.cwd()
end

---@type table<number, string>
M.cache = {}

function M.setup()
    vim.api.nvim_create_user_command("Root", function()
        info()
    end, { desc = "Roots for the current buffer" })
    vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
        group = util.augroup("root_cache", { clear = true }),
        callback = function(event)
            M.cache[event.buf] = nil
        end,
    })
end

---@param opts? { normalize?: boolean, buf?: number }
---@return string
function M.get(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    local ret = M.cache[buf]

    if not ret then
        local roots = detect({ all = false, buf = buf })
        ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
        M.cache[buf] = ret
    end

    if opts and opts.normalize then
        return ret
    end

    return util.is_win() and ret:gsub("/", "\\") or ret
end

return M
