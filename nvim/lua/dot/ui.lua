local config = require("dot.config")
local util = require("dot.util")

local M = {}

local git_branch = ""
local git_buf = -1

local function update_statusline_git_branch()
    local buf = vim.api.nvim_get_current_buf()
    if buf == git_buf and git_branch ~= "" then
        return
    end

    local head = vim.b.gitsigns_head
    if head and head ~= "" then
        local icon = config.enable_icons and config.icons.statusline.branch or "/ "
        git_branch = icon .. head .. " "
        git_buf = buf
        return
    end

    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")

    if vim.v.shell_error ~= 0 then
        git_branch = ""
        git_buf = buf

        return
    end

    branch = branch:gsub("%s+", "")
    if branch == "" then
        git_branch = ""
        git_buf = buf

        return
    end

    local icon = config.enable_icons and config.icons.statusline.branch or "/ "

    -- Include the trailing space in the branch so there is no extra space when the branch is empty.
    git_branch = icon .. branch .. " "
    git_buf = buf
end

local function set_statusline_highlights()
    vim.api.nvim_set_hl(0, "StatusLineErrors", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "StatusLineWarnings", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "StatusLineInfo", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "StatusLineHint", { link = "DiagnosticHint" })

    vim.cmd("redrawstatus!")
end

local function get_statusline()
    local line = {}

    table.insert(line, "%<")

    -- The highlight group and value for the current Git branch
    table.insert(line, "%#StatusLineGitBranch#")
    table.insert(line, "%{luaeval('require(\"dot.ui\").statusline_branch_space()')}")
    table.insert(line, "%{luaeval('require(\"dot.ui\").statusline_branch()')}")
    table.insert(line, "%*")

    -- Diagnostics symbols
    table.insert(line, "%{%luaeval('require(\"dot.ui\").statusline_diagnostics()')%}")

    -- File type
    table.insert(line, "%{%luaeval('require(\"dot.ui\").statusline_filetype_icon()')%}")

    -- Current file and file flags
    table.insert(line, "%f %h%w%m%r")

    -- Section separation point
    table.insert(line, "%=")

    -- Line and column and the ruler
    table.insert(line, "%-14.(%l,%c%V%) %P")

    return table.concat(line, "")
end

function M.setup()
    if config.enable_statusline then
        vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged", "BufEnter" }, {
            group = util.augroup("git_cache", { clear = true }),
            callback = function()
                vim.schedule(function()
                    update_statusline_git_branch()
                    vim.cmd("redrawstatus!")
                end)
            end,
        })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = util.augroup("statusline_hl", { clear = true }),
            callback = function()
                set_statusline_highlights()
            end,
        })

        if config.enable_statusline then
            vim.opt.statusline = get_statusline()
        end

        vim.schedule(update_statusline_git_branch)
        set_statusline_highlights()
    end
end

function M.statusline_branch()
    return git_branch
end

function M.statusline_branch_space()
    return M.statusline_branch() ~= "" and " " or ""
end

function M.statusline_diagnostics()
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

function M.statusline_filetype_icon()
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
        return " "
    end

    local icon, icon_highlight_group = devicons.get_icon(vim.fn.expand("%:t"))
    if icon == nil then
        icon, icon_highlight_group = devicons.get_icon_by_filetype(vim.bo.filetype)
    end

    if icon == nil and icon_highlight_group == nil then
        icon = ""
        icon_highlight_group = "DevIconDefault"
    end

    return " %#" .. icon_highlight_group .. "#" .. icon .. "%* "
end

function M.pack_specs()
    return {
        {
            src = "https://github.com/lewis6991/gitsigns.nvim",
            version = vim.version.range("2.0.0"),
        },
    }
end

return M
