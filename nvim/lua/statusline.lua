local config = require("config")
local util = require("util")

local M = {}

function M.get()
    local line = {}

    table.insert(line, "%<")

    -- The highlight group and value for the current Git branch
    table.insert(line, "%#StatusLineGitBranch#")
    table.insert(line, "%{luaeval('require(\"statusline\").branch_space()')}")
    table.insert(line, "%{luaeval('require(\"statusline\").branch()')}")
    table.insert(line, "%*")

    -- Diagnostics symbols
    table.insert(line, "%{%luaeval('require(\"statusline\").diagnostics()')%}")

    -- File type
    table.insert(line, "%{%luaeval('require(\"statusline\").ft_icon()')%}")

    -- Current file and file flags
    table.insert(line, "%f %h%w%m%r")

    -- Section separation point
    table.insert(line, "%=")

    -- Line and column and the ruler
    table.insert(line, "%-14.(%l,%c%V%) %P")

    return table.concat(line, "")
end

M._git_branch = ""
M._git_buf = -1

function M.branch()
    return M._git_branch
end

function M.branch_space()
    return M.branch() ~= "" and " " or ""
end

function M._update_git_branch()
    local buf = vim.api.nvim_get_current_buf()
    if buf == M._git_buf and M._git_branch ~= "" then
        return
    end

    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")

    if vim.v.shell_error ~= 0 then
        M._git_branch = ""
        M._git_buf = buf

        return
    end

    branch = branch:gsub("%s+", "")
    if branch == "" then
        M._git_branch = ""
        M._git_buf = buf

        return
    end

    local icon = config.enable_icons and config.icons.statusline.branch or "/ "

    -- Include the trailing space in the branch so there is no extra space when the branch is empty.
    M._git_branch = icon .. branch .. " "
    M._git_buf = buf
end

function M.diagnostics()
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

    return " " .. table.concat(parts, " ")
end

function M.ft_icon()
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

function M._set_highlights()
    if config.colorscheme == "catppuccin" then
        local palette = require("catppuccin.palettes").get_palette(
            vim.o.background == "dark" and config.colorscheme_dark_variant or config.colorscheme_light_variant
        )

        vim.api.nvim_set_hl(0, "StatusLineGitBranch", { bg = palette.blue, fg = palette.mantle })
    elseif config.colorscheme == "tokyonight" then
        local colors = require("tokyonight.colors").setup({
            style = vim.o.background == "dark" and config.colorscheme_dark_variant or config.colorscheme_light_variant,
        })
        vim.api.nvim_set_hl(0, "StatusLineGitBranch", { bg = colors.blue, fg = colors.bg })
    end

    vim.api.nvim_set_hl(0, "StatusLineErrors", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "StatusLineWarnings", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "StatusLineInfo", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "StatusLineHint", { link = "DiagnosticHint" })

    vim.cmd("redrawstatus!")
end

function M.setup()
    vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged", "BufEnter" }, {
        group = util.augroup("git_cache", { clear = true }),
        callback = function()
            vim.schedule(function()
                M._update_git_branch()
                vim.cmd("redrawstatus!")
            end)
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = util.augroup("statusline_hl", { clear = true }),
        callback = function()
            M._set_highlights()
        end,
    })
    vim.schedule(M._update_git_branch)
    M._set_highlights()
end

return M
