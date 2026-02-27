if vim.loader and vim.loader.enable then
    vim.loader.enable()
end

--------------------------------------------------------------------------------
-- OPTIONS ---------------------------------------------------------------------
--------------------------------------------------------------------------------

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = false
vim.g.netrw_list_hide = "^\\.DS_Store$"
vim.g.root_spec = { "lsp", { ".git" }, "cwd" }
vim.g.zig_fmt_autosave = false

---@type boolean
local autoformat = true

---@type integer
local formatting_timeout_ms = 3000

---@type boolean
local prettier_require_config = true

---Some icons I've found for various things.
local icons = {
    diagnostics = {
        error = "󰅚 ",
        warn = "󰀪 ",
        info = "󰋽 ",
        hint = "󰌶 ",
    },
    kinds = {
        Array = " ",
        Boolean = "󰨙 ",
        Class = " ",
        Codeium = "󰘦 ",
        Color = " ",
        Control = " ",
        Collapsed = " ",
        Constant = "󰏿 ",
        Constructor = " ",
        Copilot = " ",
        Enum = " ",
        EnumMember = " ",
        Event = " ",
        Field = " ",
        File = " ",
        Folder = " ",
        Function = "󰊕 ",
        Interface = " ",
        Key = " ",
        Keyword = " ",
        Method = "󰊕 ",
        Module = " ",
        Namespace = "󰦮 ",
        Null = " ",
        Number = "󰎠 ",
        Object = " ",
        Operator = " ",
        Package = " ",
        Property = " ",
        Reference = " ",
        Snippet = "󱄽 ",
        String = " ",
        Struct = "󰆼 ",
        Supermaven = " ",
        TabNine = "󰏚 ",
        Text = " ",
        TypeParameter = " ",
        Unit = " ",
        Value = " ",
        Variable = "󰀫 ",
    },
    statusline = {
        branch = " ",
    },
}

---@type "native" | "nvim-cmp"
vim.g.cmp = "nvim-cmp"

---@type "netrw" | "oil"
vim.g.file_explorer = "oil"

---@type boolean
vim.g.enable_icons = true

---@type boolean
vim.g.enable_statusline = true

---@type "telescope"
vim.g.picker = "telescope"

vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = "80"
vim.opt.completeopt = "menu,menuone,noselect,popup"
vim.opt.expandtab = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.formatexpr = "v:lua.formatexpr()"
vim.opt.guicursor = ""
vim.opt.ignorecase = true
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.showbreak = "> "
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.title = true

--------------------------------------------------------------------------------
-- KEYMAPS ---------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Make up and down take line wrapping into account.
vim.keymap.set({ "n", "o", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "o", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Return to file explorer.
if vim.g.file_explorer == "netrw" then
    vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Resume to file explorer" })
elseif vim.g.file_explorer == "oil" then
    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Resume to file explorer" })
else
    vim.notify("[keymaps] invalid file explorer option", vim.log.levels.WARN)
end

-- Clear highlights on search and stop snippets.
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
    vim.cmd("noh")
    if vim.snippet then
        vim.snippet.stop()
    end
    return "<esc>"
end, { expr = true, desc = "Clear highlights and stop snippet" })

-- Better indenting.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Toggles
vim.keymap.set("n", "<leader>uh", function()
    -- TODO: This applies to the current buffer, should it be for all?
    local state = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not state, { bufnr = 0 })
    if state then
        vim.notify("Disabled inlay hints", vim.log.levels.INFO)
    else
        vim.notify("Enabled inlay hints", vim.log.levels.INFO)
    end
end)

-- Delete without yanking.
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

--------------------------------------------------------------------------------
-- GENERAL UTILITIES -----------------------------------------------------------
--------------------------------------------------------------------------------

---Create an autocommand group.
---@param name string
---@param opts? vim.api.keyset.create_augroup
---@return integer
local function augroup(name, opts)
    opts = opts ~= nil and opts or {}
    opts.clear = opts.clear ~= nil and opts.clear or true
    return vim.api.nvim_create_augroup("anttikivi_" .. name, opts)
end

---@type "idle" | "building" | "done" | "failed"
local fzf_build_state = "idle"

---Build the native fzf plugin for Telescope. This function ensures that only one event can run the build at a time.
---@param path string
---@return boolean
local function build_telescope_fzf(path)
    if fzf_build_state == "building" then
        vim.notify("telescope-fzf-native.nvim build already in progress", vim.log.levels.INFO)
        return false
    elseif fzf_build_state == "done" then
        return true
    end

    fzf_build_state = "building"

    ---@type string[][]?
    local build_cmd = nil

    if vim.fn.executable("cmake") == 1 then
        build_cmd = {
            {
                "cmake",
                "-S.",
                "-Bbuild",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
            },
            {
                "cmake",
                "--build",
                "build",
                "--config",
                "Release",
            },
        }
    elseif vim.fn.executable("make") == 1 then
        build_cmd = {
            { "make" },
        }
    else
        vim.notify("cannot built telescope-fzf-native.nvim, no suitable tool", vim.log.levels.ERROR)
        fzf_build_state = "failed"
        return false
    end

    for _, cmd in ipairs(build_cmd) do
        local obj = vim.system(cmd, { cwd = path }):wait()
        if obj.code ~= 0 then
            vim.notify("failed to build telescope-fzf-native.nvim with " .. cmd[1], vim.log.levels.ERROR)
            vim.notify(obj.stderr, vim.log.levels.ERROR)
            fzf_build_state = "failed"
            return false
        end
    end

    fzf_build_state = "done"
    vim.notify("built telescope-fzf-native.nvim", vim.log.levels.INFO)

    return true
end

local CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
local function create_undo()
    if vim.api.nvim_get_mode().mode == "i" then
        vim.api.nvim_feedkeys(CREATE_UNDO, "n", false)
    end
end

local function debounce(ms, fn)
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
local function memoize(fn)
    return function(...)
        local key = vim.inspect({ ... })
        memoize_cache[fn] = memoize_cache[fn] or {}

        if memoize_cache[fn][key] == nil then
            memoize_cache[fn][key] = fn(...)
        end

        return memoize_cache[fn][key]
    end
end

---@generic R
---@param fn fun(): R?
---@param opts? string | { msg: string, on_error: fun(msg) }
---@return R
local function try(fn, opts)
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

--------------------------------------------------------------------------------
-- PACKAGES --------------------------------------------------------------------
--------------------------------------------------------------------------------

local pack_specs = {
    {
        src = "https://github.com/anttikivi/lucid.nvim",
        version = "b8dac7949c93a824e353bbd24f188b27ebdf8512",
    },
    {
        src = "https://github.com/f-person/auto-dark-mode.nvim",
        version = "e300259ec777a40b4b9e3c8e6ade203e78d15881",
    },
    {
        src = "https://github.com/folke/lazydev.nvim",
        version = "main",
    },
    {
        src = "https://github.com/lewis6991/gitsigns.nvim",
        version = "main",
    },
    {
        src = "https://github.com/mason-org/mason.nvim",
        version = "main",
    },
    {
        src = "https://github.com/mfussenegger/nvim-lint",
        version = "master",
    },
    {
        src = "https://github.com/nvim-lua/plenary.nvim",
        version = "master",
    },
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "main",
    },
    {
        src = "https://github.com/stevearc/conform.nvim",
        version = "master",
    },
    {
        src = "https://github.com/ThePrimeagen/harpoon",
        version = "harpoon2",
    },
    {
        src = "https://codeberg.org/ziglang/zig.vim",
        version = "master",
    },
}

if vim.g.cmp == "nvim-cmp" then
    vim.list_extend(pack_specs, {
        {
            src = "https://github.com/hrsh7th/nvim-cmp",
            version = "main",
        },
        {
            src = "https://github.com/hrsh7th/cmp-nvim-lsp",
            version = "main",
        },
        {
            src = "https://github.com/hrsh7th/cmp-buffer",
            version = "main",
        },
        {
            src = "https://github.com/hrsh7th/cmp-path",
            version = "main",
        },
    })
end

if vim.g.file_explorer == "oil" then
    pack_specs[#pack_specs + 1] = {
        src = "https://github.com/stevearc/oil.nvim",
        version = "master",
    }
end

if vim.g.enable_icons then
    pack_specs[#pack_specs + 1] = {
        src = "https://github.com/nvim-mini/mini.icons",
        version = "main",
    }
end

if vim.g.picker == "telescope" then
    vim.list_extend(pack_specs, {
        {
            src = "https://github.com/nvim-telescope/telescope.nvim",
            version = "master",
        },
        {
            src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
            version = "main",
        },
    })
end

vim.api.nvim_create_autocmd("PackChanged", {
    group = augroup("pack_changed"),
    callback = function(ev)
        if ev.data.spec.name == "mason.nvim" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("mason")
                vim.cmd("MasonUpdate")
            end
        elseif ev.data.spec.name == "nvim-treesitter" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("nvim-treesitter")
                vim.cmd("TSUpdate")
            end
        elseif ev.data.spec.name == "telescope-fzf-native.nvim" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                if build_telescope_fzf(ev.data.path) then
                    vim.defer_fn(function()
                        if not pcall(require("telescope").load_extension, "fzf") then
                            vim.notify("failed to load fzf extension for telescope", vim.log.levels.WARN)
                        end
                    end, 100)
                end
            end
        end
    end,
})

vim.pack.add(pack_specs)

--------------------------------------------------------------------------------
-- ICONS -----------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO: Should we move this section elsewhere?
if vim.g.enable_icons then
    require("mini.icons").setup()
    MiniIcons.mock_nvim_web_devicons()
end

--------------------------------------------------------------------------------
-- FILETYPES -------------------------------------------------------------------
--------------------------------------------------------------------------------

vim.filetype.add({
    extension = {
        tf = "opentofu",
        tfvars = "opentofu-vars",
    },
})

--------------------------------------------------------------------------------
-- FORMATTER -------------------------------------------------------------------
--------------------------------------------------------------------------------

---@type config.Formatter[]
local formatters = {}

---Register a "top-level" formatter. These are things like the language server client and conform.nvim.
---@param formatter config.Formatter
local function register_formatter(formatter)
    formatters[#formatters + 1] = formatter

    table.sort(formatters, function(a, b)
        return a.priority > b.priority
    end)
end

---Check if a Prettier config exists in the given Conform context.
---@param ctx conform.Context
---@return boolean
local prettier_has_config = memoize(function(ctx)
    vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
    return vim.v.shell_error == 0
end)

local conform = require("conform")

conform.setup({
    default_format_opts = {
        timeout_ms = formatting_timeout_ms,
        async = false,
        quiet = false,
        lsp_format = "fallback",
    },
    formatters_by_ft = {
        bash = { "shfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        javascript = { "oxfmt", "prettier" },
        json = { "oxfmt", "prettier" },
        jsonc = { "oxfmt", "prettier" },
        lua = { "stylua" },
        markdown = { "oxfmt", "prettier" },
        opentofu = { "tofu_fmt" },
        ["opentofu-vars"] = { "tofu_fmt" },
        sh = { "shfmt" },
        toml = { "taplo" },
        typescript = { "oxfmt", "prettier" },
        yaml = { "oxfmt", "prettier" },
        ["yaml.ansible"] = { "oxfmt", "prettier" },
        zig = { "zigfmt" },
    },
    formatters = {
        oxfmt = {
            append_args = function(_, ctx)
                local root = vim.fs.root(ctx.dirname, { ".oxfmtrc.json", ".oxfmtrc.jsonc" })
                if not root then
                    return { "--config", vim.fs.abspath("~/src/personal/dotfiles/oxfmtrc.json") }
                end

                return {}
            end,
        },
        prettier = {
            condition = function(_, ctx)
                return not prettier_require_config or prettier_has_config(ctx)
            end,
        },
    },
})

register_formatter({
    name = "conform.nvim",
    priority = 100,
    primary = true,
    format = function(buf)
        conform.format({ bufnr = buf })
    end,
    sources = function(buf)
        local result = conform.list_formatters(buf)
        ---@param v conform.FormatterInfo
        return vim.tbl_map(function(v)
            return v.name
        end, result)
    end,
})

---@param buf number?
local function is_formatter_enabled(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local gaf = vim.g.autoformat
    local baf = vim.b[buf].autoformat

    if baf ~= nil then
        return baf
    end

    return gaf == nil or gaf
end

---@param buf number?
---@return (config.Formatter | { active: boolean, resolved: string[] })[]
local function resolve_formatter(buf)
    local have_primary = false
    buf = buf or vim.api.nvim_get_current_buf()

    ---@param formatter config.Formatter
    return vim.tbl_map(function(formatter)
        local sources = formatter.sources(buf)
        local active = #sources > 0 and (not formatter.primary or not have_primary)
        have_primary = have_primary or (active and formatter.primary) or false

        return setmetatable({
            active = active,
            resolved = sources,
        }, { __index = formatter })
    end, formatters)
end

---@param opts { force: boolean?, buf: number? }?
local function format(opts)
    opts = opts or {}

    local buf = opts.buf or vim.api.nvim_get_current_buf()

    if not ((opts and opts.force) or is_formatter_enabled(buf)) then
        return
    end

    local done = false

    for _, formatter in ipairs(resolve_formatter(buf)) do
        if formatter.active then
            done = true
            try(function()
                return formatter.format(buf)
            end, { msg = "Formatter `" .. formatter.name .. "` failed" })
        end
    end

    if not done and opts and opts.force then
        vim.notify("no formatter available", vim.log.levels.WARN)
    end
end

function _G.formatexpr()
    local use_conform = false
    ---@type vim.pack.PlugData[]
    local plugins = vim.pack.get()
    for _, p in ipairs(plugins) do
        if p.spec.name == "conform.nvim" and p.active then
            use_conform = true
        end
    end

    if use_conform then
        return require("conform").formatexpr()
    end

    return vim.lsp.formatexpr({ timeout_ms = formatting_timeout_ms })
end

--------------------------------------------------------------------------------
-- LSP -------------------------------------------------------------------------
--------------------------------------------------------------------------------

---@type string[]
local server_names = {}
---@type string[]
local enabled_servers = {}
local lsp_path = vim.fn.stdpath("config") .. "/lsp"
for name, entry_type in vim.fs.dir(lsp_path) do
    if entry_type == "file" and name:sub(-4) == ".lua" then
        local server_name = name:gsub("%.lua$", "")
        local config_path = lsp_path .. "/" .. name

        local ok, config = pcall(dofile, config_path)
        if not ok then
            vim.notify(("failed to load LSP config %q: %s"):format(server_name, config), vim.log.levels.ERROR)
        elseif type(config) ~= "table" then
            vim.notify(("loading LSP config %q did not return a table"):format(server_name), vim.log.levels.WARN)
        else
            ---@cast config config.LspConfig
            if config.enabled ~= false then
                enabled_servers[#enabled_servers + 1] = server_name
            end
        end

        server_names[#server_names + 1] = server_name
    end
end

vim.lsp.enable(enabled_servers)

---Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param fn fun(client: vim.lsp.Client, buf: integer)
---@param name? string
local function on_attach(fn, name)
    return vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local buffer = args.buf ---@type integer
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and (not name or client.name == name) then
                fn(client, buffer)
            end
        end,
    })
end

on_attach(function(_, buf)
    -- Neovim now provides some default mappings so I don't need to add my own:
    -- "grn": vim.lsp.buf.rename()
    -- "gra": vim.lsp.buf.code_action()
    -- "grr": vim.lsp.buf.references()
    -- "gri": vim.lsp.buf.implementation()
    -- "grt": vim.lsp.buf.type_definition()
    -- "gO": vim.lsp.buf.document_symbol()
    -- CTRL-S: vim.lsp.buf.signature_help()
    vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = buf })
end)

on_attach(function(client, buf)
    if client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    end
end)

---@param filter? config.lsp.Filter
---@return vim.lsp.Client[]
local function get_lsp_clients(filter)
    local clients = vim.lsp.get_clients(filter)
    return filter and filter.filter and vim.tbl_filter(filter.filter, clients) or clients
end

register_formatter({
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
        vim.lsp.buf.format({ timeout_ms = formatting_timeout_ms, bufnr = buf })
    end,
    sources = function(buf)
        local clients = get_lsp_clients({ bufnr = buf })
        ---@param client vim.lsp.Client
        local ret = vim.tbl_filter(function(client)
            return client:supports_method("textDocument/formatting")
                or client:supports_method("textDocument/rangeFormatting")
        end, clients)
        ---@param client vim.lsp.Client
        return vim.tbl_map(function(client)
            return client.name
        end, ret)
    end,
})

require("lazydev").setup({
    library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
})

--------------------------------------------------------------------------------
-- COMPLETIONS -----------------------------------------------------------------
--------------------------------------------------------------------------------

---This is a better implementation of `cmp.confirm`:
--- * check if the completion menu is visible without waiting for running sources
--- * create an undo point before confirming
---This function is both faster and more reliable.
---@param opts? { select: boolean, behavior: cmp.ConfirmBehavior }
local function cmp_confirm(opts)
    local cmp = require("cmp")
    opts = vim.tbl_extend("force", {
        select = true,
        behavior = cmp.ConfirmBehavior.Insert,
    }, opts or {})
    return function(fallback)
        if cmp.visible() then
            create_undo()
            if cmp.confirm(opts) then
                return
            end
        end
        return fallback()
    end
end

if vim.g.cmp == "native" then
    on_attach(function(client, buffer)
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
        end
    end)
elseif vim.g.cmp == "nvim-cmp" then
    local cmp = require("cmp")
    local defaults = require("cmp.config.default")()

    local auto_select = true
    local keymap = {
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-y>"] = cmp_confirm({ select = true }),
    }

    local opts = {
        snippet = {
            expand = function(args)
                return vim.snippet.expand(args.body)
            end,
        },
        completion = {
            completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
        },
        preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
        mapping = cmp.mapping.preset.insert(keymap),
        sources = cmp.config.sources({
            { name = "lazydev" },
            { name = "nvim_lsp" },
            { name = "path" },
        }, {
            { name = "buffer" },
        }),
        sorting = defaults.sorting,
    }

    cmp.setup(opts)

    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    vim.lsp.config("*", {
        capabilities = capabilities,
    })
end

--------------------------------------------------------------------------------
-- DIAGNOSTICS -----------------------------------------------------------------
--------------------------------------------------------------------------------

vim.diagnostic.config({
    signs = {
        text = vim.g.enable_icons and {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.warn,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
        } or {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
    virtual_lines = false,
    virtual_text = true,
})

--------------------------------------------------------------------------------
-- ROOT DIRECTORY DETECTION ----------------------------------------------------
--------------------------------------------------------------------------------

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
    local clients = get_lsp_clients({ bufnr = buf })
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

---@param spec config.RootSpec
---@return config.RootFn
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

---@param opts? { buf?: number, spec?: config.RootSpec[], all?: boolean }
local function detect_root(opts)
    opts = opts or {}
    opts.spec = opts.spec or vim.g.root_spec
    opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

    local ret = {} ---@type config.Root[]

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
local function get_root(opts)
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

--------------------------------------------------------------------------------
-- MASON -----------------------------------------------------------------------
--------------------------------------------------------------------------------

local mason = require("mason")
local mason_registry = require("mason-registry")
local _ = require("mason-core.functional")

mason.setup()

local cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)

mason_registry:on("update:success", function()
    cached_mason_specs = _.lazy(mason_registry.get_all_package_specs)
end)

mason_registry:on("package:install:success", function()
    vim.defer_fn(function()
        vim.api.nvim_exec_autocmds("FileType", {
            buffer = vim.api.nvim_get_current_buf(),
        })
    end, 100)
end)

---@type table<string, string>
local package_to_lspconfig = {}
for _, pkg_spec in ipairs(cached_mason_specs()) do
    local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig")
    if lspconfig then
        package_to_lspconfig[pkg_spec.name] = lspconfig
    end
end

---@type table<string, string>
local lspconfig_to_package = _.invert(package_to_lspconfig)

---Packages that should be installed by Mason in addition to the language servers.
---@type string[]
local ensure_installed = {
    "ansible-lint",
    "clang-format",
    "oxfmt",
    "oxlint",
    "prettier",
    "selene",
    "shfmt",
    "stylua",
    "taplo",
}

local Optional = require("mason-core.optional")
local Package = require("mason-core.package")

mason_registry.refresh(vim.schedule_wrap(function()
    if #vim.api.nvim_list_uis() ~= 0 then -- not in headless mode
        -- Install language servers.
        for _, server_name in ipairs(server_names) do
            local parsed_name, version = Package.Parse(server_name)
            Optional.of_nilable(lspconfig_to_package[parsed_name])
                :map(function(name)
                    local ok, pkg = pcall(mason_registry.get_package, name)
                    if ok then
                        return pkg
                    end
                end)
                :if_present(
                    ---@param pkg Package
                    function(pkg)
                        if not pkg:is_installed() and not pkg:is_installing() then
                            local name = package_to_lspconfig[pkg.name]
                            vim.notify(("[mason] installing %s"):format(name))
                            pkg:install(
                                { version = version },
                                vim.schedule_wrap(function(success)
                                    if success then
                                        vim.notify(("[mason] %s was successfully installed"):format(name))
                                    else
                                        vim.notify(
                                            ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                                                name
                                            ),
                                            vim.log.levels.ERROR
                                        )
                                    end
                                end)
                            )
                        end
                    end
                )
                :if_not_present(function()
                    vim.notify(("[mason] server %q is not a valid entry"):format(parsed_name), vim.log.levels.WARN)
                end)
        end

        -- Install rest of the tools.
        for _, tool in ipairs(ensure_installed) do
            local pkg = mason_registry.get_package(tool)
            if not pkg:is_installed() and not pkg:is_installing() then
                vim.notify(("[mason] installing %s"):format(tool))
                pkg:install(
                    {},
                    vim.schedule_wrap(function(success)
                        if success then
                            vim.notify(("[mason] %s was successfully installed"):format(tool))
                        else
                            vim.notify(
                                ("[mason] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                                    tool
                                ),
                                vim.log.levels.ERROR
                            )
                        end
                    end)
                )
            end
        end
    end
end))

--------------------------------------------------------------------------------
-- LINTER ----------------------------------------------------------------------
--------------------------------------------------------------------------------

---@type table<string, config.Linter>
local linters = {
    selene = {
        args = {
            "--config",
            vim.fs.find({ "selene.toml" }, { path = get_root({ normalize = true }), upward = true })[1],
            "--display-style",
            "json",
            "-",
        },
        condition = function()
            return vim.fs.find({ "selene.toml" }, { path = get_root({ normalize = true }), upward = true })[1]
        end,
    },
}

local lint = require("lint")

for name, linter in pairs(linters) do
    if type(linter) == "table" and type(lint.linters[name]) == "table" then
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] --[[@as table]], linter)
        if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}

            vim.list_extend(lint.linters[name].args, linter.prepend_args)
        end
    else
        lint.linters[name] = linter
    end
end

lint.linters_by_ft = {
    c = { "clangtidy" },
    cpp = { "clangtidy" },
    javascript = { "oxlint" },
    lua = { "selene" },
    opentofu = { "tofu" },
    ["opentofu-vars"] = { "tofu" },
    typescript = { "oxlint" },
    -- zig = { "zlint" }, -- let's try this out...
}

local function try_lint()
    local names = lint._resolve_linter_by_ft(vim.bo.filetype)

    if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
    end
    vim.list_extend(names, lint.linters_by_ft["*"] or {})

    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    names = vim.tbl_filter(function(name)
        local linter = lint.linters[name] --[[@as config.Linter]]
        if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
        end

        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, names)

    if #names > 0 then
        lint.try_lint(names)
    end
end

--------------------------------------------------------------------------------
-- TREE-SITTER -----------------------------------------------------------------
--------------------------------------------------------------------------------

local tree_sitter_ensure_installed = {
    "awk",
    "bash",
    "c",
    "cpp",
    "javascript",
    "json",
    "jsx",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "powershell",
    "terraform",
    "tsx",
    "typescript",
    "toml",
    "yaml",
    "zig",
    "zsh",
}

require("nvim-treesitter").install(tree_sitter_ensure_installed)

---@type string[]
local tree_sitter_autocmd_pattern = {}

for i, l in ipairs(tree_sitter_ensure_installed) do
    if l == "terraform" then
        tree_sitter_autocmd_pattern[i] = "opentofu"
    else
        tree_sitter_autocmd_pattern[i] = l
    end
end

-- Tree-sitter autocommands are defined here in the Tree-sitter section as I'd
-- see them so closely tied to the general Tree-sitter configuration.
vim.api.nvim_create_autocmd("FileType", {
    -- TODO: Do I want to enable different tree-sitter features depending on
    -- the language?
    pattern = tree_sitter_autocmd_pattern,
    callback = function()
        vim.treesitter.start()
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo[0][0].foldmethod = "expr"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

vim.treesitter.language.register("terraform", { "opentofu" })

--------------------------------------------------------------------------------
-- NAVIGATION ------------------------------------------------------------------
--------------------------------------------------------------------------------

if vim.g.file_explorer == "oil" then
    require("oil").setup({
        default_file_explorer = true,
        columns = {
            "icon",
            -- "permissions",
            -- "size",
            -- "mtime",
        },
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 2000,
        },
        watch_for_changes = true,
        view_options = {
            show_hidden = true,
            is_always_hidden = function(name)
                return name == ".." or name == ".DS_Store"
            end,
        },
    })
end

if vim.g.picker == "telescope" then
    local actions = require("telescope.actions")
    local telescope_config = require("telescope.config")

    local vimgrep_arguments = { unpack(telescope_config.values.vimgrep_arguments) }
    table.insert(vimgrep_arguments, "--hidden")
    table.insert(vimgrep_arguments, "--glob")
    table.insert(vimgrep_arguments, "!**/.git/*")

    require("telescope").setup({
        defaults = {
            mappings = {
                i = {
                    ["<esc>"] = actions.close,
                },
            },
            vimgrep_arguments = vimgrep_arguments,
        },
        pickers = {
            find_files = {
                find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            },
        },
    })
    if not pcall(require("telescope").load_extension, "fzf") then
        vim.notify("failed to load fzf extension for telescope, trying to build...", vim.log.levels.WARN)
        ---@type string?
        local telescope_fzf_path = nil
        local plugins = vim.pack.get()
        for _, p in ipairs(plugins) do
            if p.spec.name == "telescope-fzf-native.nvim" and p.active then
                telescope_fzf_path = p.path
                break
            end
        end

        if telescope_fzf_path and build_telescope_fzf(telescope_fzf_path) then
            vim.defer_fn(function()
                if not pcall(require("telescope").load_extension, "fzf") then
                    vim.notify("failed to load fzf extension for telescope", vim.log.levels.WARN)
                end
            end, 100)
        else
            vim.notify("failed to find path for fzf extension for telescope", vim.log.levels.WARN)
        end
    end

    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume picker" })
end

local harpoon = require("harpoon")

harpoon:setup({
    settings = {
        save_on_toggle = true,
    },
})
vim.keymap.set("n", "<C-h>", function()
    harpoon:list():add()
end)
vim.keymap.set("n", "<leader>h", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
end)
local ordinal = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth" }
for i, v in ipairs(ordinal) do
    vim.keymap.set("n", "<leader>" .. i, function()
        harpoon:list():select(i)
    end, { desc = string.format("Switch to the %s harpooned file", v) })
end

--------------------------------------------------------------------------------
-- STATUSLINE ------------------------------------------------------------------
--------------------------------------------------------------------------------

local statusline_git_branch = ""
local statusline_git_buf = -1

function _G.statusline_branch()
    return statusline_git_branch
end

function _G.statusline_branch_space()
    return statusline_git_branch ~= "" and " " or ""
end

function _G.statusline_diagnostics()
    local count = vim.diagnostic.count(0)
    local error_count = count[vim.diagnostic.severity.ERROR] or 0
    local warn_count = count[vim.diagnostic.severity.WARN] or 0
    local info_count = count[vim.diagnostic.severity.INFO] or 0
    local hint_count = count[vim.diagnostic.severity.HINT] or 0

    local signs = vim.diagnostic.config().signs.text
        or {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        }

    local parts = {}

    if error_count > 0 then
        table.insert(parts, "%#StatusLineErrors#" .. signs[vim.diagnostic.severity.ERROR] .. error_count)
    end

    if warn_count > 0 then
        table.insert(parts, "%#StatusLineWarnings#" .. signs[vim.diagnostic.severity.WARN] .. warn_count)
    end

    if info_count > 0 then
        table.insert(parts, "%#StatusLineInfo#" .. signs[vim.diagnostic.severity.INFO] .. info_count)
    end

    if hint_count > 0 then
        table.insert(parts, "%#StatusLineHint#" .. signs[vim.diagnostic.severity.HINT] .. hint_count)
    end

    if #parts == 0 then
        return ""
    end

    return " " .. table.concat(parts, " ") .. "%*"
end

function _G.statusline_filetype_icon()
    if not _G.MiniIcons then
        return " "
    end

    local icon, hl
    local name = vim.api.nvim_buf_get_name(0)
    local ft = vim.bo.filetype

    -- Attempt to get icon safely
    local ok = pcall(function()
        if ft ~= "" then
            icon, hl = MiniIcons.get("filetype", ft)
        elseif name ~= "" then
            icon, hl = MiniIcons.get("file", name)
        else
            icon, hl = MiniIcons.get("filetype", "text")
        end
    end)

    if not ok or not icon then
        return ""
    end

    return " %#" .. hl .. "#" .. icon .. "%* "
end

local function statusline()
    local line = {}

    table.insert(line, "%<")
    table.insert(line, "%#StatusLineGitBranch#")
    table.insert(line, "%{luaeval('_G.statusline_branch_space()')}")
    table.insert(line, "%{luaeval('_G.statusline_branch()')}")
    table.insert(line, "%*")
    table.insert(line, "%{%luaeval('_G.statusline_diagnostics()')%}")
    table.insert(line, "%{%luaeval('_G.statusline_filetype_icon()')%}")
    table.insert(line, "%f %h%w%m%r")
    table.insert(line, "%=")
    table.insert(line, "%-14.(%l,%c%V%) %P")

    return table.concat(line, "")
end

local function update_statusline_git_branch()
    local buf = vim.api.nvim_get_current_buf()
    if buf == statusline_git_buf and statusline_git_branch ~= "" then
        return
    end

    local head = vim.b.gitsigns_head
    if head and head ~= "" then
        local icon = vim.g.enable_icons and icons.statusline.branch or "/ "
        statusline_git_branch = icon .. head .. " "
        statusline_git_buf = buf
        return
    end

    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")

    if vim.v.shell_error ~= 0 then
        statusline_git_branch = ""
        statusline_git_buf = buf

        return
    end

    branch = branch:gsub("%s+", "")
    if branch == "" then
        statusline_git_branch = ""
        statusline_git_buf = buf

        return
    end

    local icon = vim.g.enable_icons and icons.statusline.branch or "/ "

    -- Include the trailing space in the branch so there is no extra space when the branch is empty.
    statusline_git_branch = icon .. branch .. " "
    statusline_git_buf = buf
end

local function set_statusline_highlights()
    vim.api.nvim_set_hl(0, "StatusLineErrors", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "StatusLineWarnings", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "StatusLineInfo", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "StatusLineHint", { link = "DiagnosticHint" })

    vim.schedule(function()
        vim.cmd("redrawstatus!")
    end)
end

if vim.g.enable_statusline then
    vim.opt.statusline = statusline()
    vim.schedule(update_statusline_git_branch)
    set_statusline_highlights()
end

--------------------------------------------------------------------------------
-- AUTOCOMMANDS ----------------------------------------------------------------
--------------------------------------------------------------------------------

-- Format on save.
if autoformat then
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup("formatting"),
        callback = function(event)
            format({ buf = event.buf })
        end,
    })
end

-- Run linters automatically.
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = debounce(100, try_lint),
})

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank()
    end,
})

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local last_lsp_progress = 0

-- Show LSP progress.
vim.api.nvim_create_autocmd("LspProgress", {
    group = augroup("lsp_progress"),
    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
    callback = function(ev)
        local now = vim.uv.now()
        if ev.data.params.value.kind ~= "end" and (now - last_lsp_progress) < 100 then
            return
        end
        last_lsp_progress = now
        vim.notify(
            -- TODO: This is not an optimal solution but kinda nice for now.
            ev.data.params.value.kind == "end" and " Workspace loaded"
                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] .. " " .. vim.lsp.status(),
            vim.log.levels.INFO
        )
    end,
})

-- Update root directory.
vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
    group = augroup("root_cache", { clear = true }),
    callback = function(event)
        root_cache[event.buf] = nil
    end,
})

-- Update statusline.
if vim.g.enable_statusline then
    vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged", "BufEnter" }, {
        group = augroup("git_cache", { clear = true }),
        callback = function()
            vim.schedule(function()
                update_statusline_git_branch()
                vim.cmd("redrawstatus!")
            end)
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = augroup("statusline_hl", { clear = true }),
        callback = function()
            set_statusline_highlights()
        end,
    })
end

vim.api.nvim_create_autocmd("PackChanged", {
    group = augroup("pack_changed"),
    callback = function(ev)
        if ev.data.spec.name == "mason.nvim" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("mason")
                vim.cmd("MasonUpdate")
            end
        elseif ev.data.spec.name == "nvim-treesitter" then
            if ev.data.kind == "install" or ev.data.kind == "update" then
                _ = require("nvim-treesitter")
                vim.cmd("TSUpdate")
            end
        end
    end,
})

--------------------------------------------------------------------------------
-- USER COMMANDS ---------------------------------------------------------------
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("Format", function()
    format({ force = true })
end, { desc = "Format selection or buffer" })

vim.api.nvim_create_user_command("FormatInfo", function()
    local buf = vim.api.nvim_get_current_buf()
    local gaf = vim.g.autoformat
    local baf = vim.b[buf].autoformat
    local lines = {
        "# Status",
        ("- [%s] global **%s**"):format(gaf and "x" or " ", gaf and "enabled" or "disabled"),
        ("- [%s] buffer **%s**"):format(
            is_formatter_enabled(buf) and "x" or " ",
            baf == nil and "inherit" or baf and "enabled" or "disabled"
        ),
    }
    local have = false

    for _, formatter in ipairs(resolve_formatter(buf)) do
        if #formatter.resolved > 0 then
            have = true
            lines[#lines + 1] = "\n# " .. formatter.name .. (formatter.active and " ***(active)***" or "")
            for _, line in ipairs(formatter.resolved) do
                lines[#lines + 1] = ("- [%s] **%s**"):format(formatter.active and "x" or " ", line)
            end
        end
    end

    if not have then
        lines[#lines + 1] = "\n***No formatters available for this buffer.***"
    end

    vim.notify(table.concat(lines, "\n"), is_formatter_enabled(buf) and vim.log.levels.INFO or vim.log.levels.WARN)
end, { desc = "Show info about the formatters for the current buffer" })

vim.api.nvim_create_user_command("Root", function()
    local spec = vim.g.root_spec
    local roots = detect_root({ all = true })
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
end, { desc = "Roots for the current buffer" })

vim.api.nvim_create_user_command("PackClean", function()
    ---@type vim.pack.PlugData[]
    local plugins = vim.pack.get()
    local clean = {}

    for _, p in ipairs(plugins) do
        if not p.active then
            clean[#clean + 1] = p.spec.name
        end
    end

    local prompt = { "Plugins to remove:" }
    for _, u in ipairs(clean) do
        prompt[#prompt + 1] = " - " .. u
    end
    prompt[#prompt + 1] = ""
    prompt[#prompt + 1] = "Continue? [Y/n] "

    local done = false
    local do_clean = false
    while not done do
        vim.ui.input({ prompt = table.concat(prompt, "\n") }, function(input)
            if input == nil then
                done = true
                return
            end

            input = input:lower()

            if input == "" or input == "y" or input == "yes" then
                done = true
                do_clean = true
            end

            if input == "n" or input == "no" then
                done = true
                return
            end
        end)

        prompt = { "", "Please input [y]es or [n]o", "Continue? [Y/n] " }
    end

    if not do_clean then
        vim.notify("\nNot cleaning", vim.log.levels.INFO)
        return
    end

    vim.notify("\nRemoving plugins...", vim.log.levels.INFO)

    vim.pack.del(clean)
end, { desc = "Clean plugins that are not active" })

vim.api.nvim_create_user_command("PackUpdate", function()
    ---@type vim.pack.PlugData[]
    local plugins = vim.pack.get()
    local update = {}

    for _, p in ipairs(plugins) do
        if p.active then
            update[#update + 1] = p.spec.name
        end
    end

    local prompt = { "Going to check updates for" }
    for _, u in ipairs(update) do
        prompt[#prompt + 1] = " - " .. u
    end
    prompt[#prompt + 1] = ""
    prompt[#prompt + 1] = "Continue? [Y/n] "

    local done = false
    local do_update = false
    while not done do
        vim.ui.input({ prompt = table.concat(prompt, "\n") }, function(input)
            if input == nil then
                done = true
                return
            end

            input = input:lower()

            if input == "" or input == "y" or input == "yes" then
                done = true
                do_update = true
            end

            if input == "n" or input == "no" then
                done = true
                return
            end
        end)

        prompt = { "", "Please input [y]es or [n]o", "Continue? [Y/n] " }
    end

    if not do_update then
        vim.notify("\nAborting update", vim.log.levels.INFO)
        return
    end

    vim.notify("\nUpdating...", vim.log.levels.INFO)

    vim.pack.update(update)
end, { desc = "Update installed plugins" })

vim.api.nvim_create_user_command("PackUpdateAll", function()
    ---@type vim.pack.PlugData[]
    local plugins = vim.pack.get()
    local update = {}
    local prompt = { "Going to check updates for" }

    for _, p in ipairs(plugins) do
        update[#update + 1] = p.spec.name
        prompt[#prompt + 1] = " - " .. p.spec.name .. " (" .. (p.active and "active" or "inactive") .. ")"
    end

    prompt[#prompt + 1] = ""
    prompt[#prompt + 1] =
        "Please note that the update does NOT take version constraints into account for plugins that are not currently active!"
    prompt[#prompt + 1] = ""
    prompt[#prompt + 1] = "Continue? [Y/n] "

    local done = false
    local do_update = false
    while not done do
        vim.ui.input({ prompt = table.concat(prompt, "\n") }, function(input)
            if input == nil then
                done = true
                return
            end

            input = input:lower()

            if input == "" or input == "y" or input == "yes" then
                done = true
                do_update = true
            end

            if input == "n" or input == "no" then
                done = true
                return
            end
        end)

        prompt = { "", "Please input [y]es or [n]o", "Continue? [Y/n] " }
    end

    if not do_update then
        vim.notify("\nAborting update", vim.log.levels.INFO)
        return
    end

    vim.notify("\nUpdating...", vim.log.levels.INFO)

    vim.pack.update(update)
end, { desc = "Update all found plugins, even those not currently active" })

--------------------------------------------------------------------------------
-- COLOR SCHEME ----------------------------------------------------------------
--------------------------------------------------------------------------------

require("auto-dark-mode").setup({ update_interval = 5000 })
vim.cmd.colorscheme("lucid")
