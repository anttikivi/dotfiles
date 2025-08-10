local util = require("util")

---@class root
---@overload fun(): string
local M = setmetatable({}, {
    __call = function(m, ...)
        return m.get(...)
    end,
})

---@class Root
---@field paths string[]
---@field spec RootSpec

---@alias RootFn fun(buf: number): (string | string[])
---@alias RootSpec string | string[] | RootFn

---@type RootSpec[]
M.spec = { "lsp", { ".git" }, "cwd" }

---@type table<number, string>
M.cache = {}

M.detectors = {}

function M.detectors.cwd()
    return { vim.uv.cwd() }
end

function M.detectors.lsp(buf)
    local bufpath = M.bufpath(buf)

    if not bufpath then
        return {}
    end

    local roots = {} ---@type string[]
    local clients = require("lsp").get_clients({ bufnr = buf })
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
        path = util.norm(path)

        return path and bufpath:find(path, 1, true) == 1 or false
    end, roots)
end

---@param patterns string[] | string
function M.detectors.pattern(buf, patterns)
    patterns = type(patterns) == "string" and { patterns } or patterns

    ---@cast patterns string[]

    local path = M.bufpath(buf) or vim.uv.cwd()
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

function M.bufpath(buf)
    return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.cwd()
    return M.realpath(vim.uv.cwd()) or ""
end

---@param opts? { buf?: number, spec?: RootSpec[], all?: boolean }
function M.detect(opts)
    opts = opts or {}
    opts.spec = opts.spec or type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
    opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

    local ret = {} ---@type Root[]

    for _, spec in ipairs(opts.spec) do
        local paths = M.resolve(spec)(opts.buf)
        paths = paths or {}
        paths = type(paths) == "table" and paths or { paths }
        local roots = {} ---@type string[]

        for _, p in ipairs(paths) do
            local pp = M.realpath(p)

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

---@param opts? { normalize?: boolean, buf?: number }
---@return string
function M.get(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    local ret = M.cache[buf]

    if not ret then
        local roots = M.detect({ all = false, buf = buf })
        ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
        M.cache[buf] = ret
    end

    if opts and opts.normalize then
        return ret
    end

    return util.is_win() and ret:gsub("/", "\\") or ret
end

function M.info()
    local spec = type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
    local roots = M.detect({ all = true })
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

function M.insert_package_json(root_files, field, fname)
    return M.root_markers_with_field(root_files, { "package.json", "package.json5" }, field, fname)
end

function M.realpath(path)
    if path == "" or path == nil then
        return nil
    end

    path = vim.uv.fs_realpath(path) or path

    return util.norm(path)
end

---@param spec RootSpec
---@return RootFn
function M.resolve(spec)
    if M.detectors[spec] then
        return M.detectors[spec]
    elseif type(spec) == "function" then
        return spec
    end

    return function(buf)
        return M.detectors.pattern(buf, spec)
    end
end

--- Appends `new_names` to `root_files` if `field` is found in any such file in any ancestor of `fname`.
---
--- NOTE: this does a "breadth-first" search, so is broken for multi-project workspaces:
--- https://github.com/neovim/nvim-lspconfig/issues/3818#issuecomment-2848836794
---
--- @param root_files string[] List of root-marker files to append to.
--- @param new_names string[] Potential root-marker filenames (e.g. `{ 'package.json', 'package.json5' }`) to inspect for the given `field`.
--- @param field string Field to search for in the given `new_names` files.
--- @param fname string Full path of the current buffer name to start searching upwards from.
function M.root_markers_with_field(root_files, new_names, field, fname)
    local path = vim.fn.fnamemodify(fname, ":h")
    local found = vim.fs.find(new_names, { path = path, upward = true })

    for _, f in ipairs(found or {}) do
        -- Match the given `field`.
        for line in io.lines(f) do
            if line:find(field) then
                root_files[#root_files + 1] = vim.fs.basename(f)
                break
            end
        end
    end

    return root_files
end

function M.setup()
    vim.api.nvim_create_user_command("Root", function()
        M.info()
    end, { desc = "Roots for the current buffer" })
    vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
        group = util.augroup("root_cache", { clear = true }),
        callback = function(event)
            M.cache[event.buf] = nil
        end,
    })
end

return M
