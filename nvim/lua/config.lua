---@class Config
local M = {
    ---@type boolean
    autoformat = true,

    ---@type "blink" | "native" | "nvim-cmp"
    cmp = "nvim-cmp",

    ---@type "catppuccin" | "rose-pine" | "tokyonight"
    colorscheme = vim.env.COLOR_SCHEME,

    ---@type "frappe" | "macchiato" | "mocha" | "main" | "moon" | "storm" | "night"
    colorscheme_dark_variant = vim.env.COLOR_SCHEME_DARK_VARIANT,

    ---@type "latte" | "dawn" | "day"
    colorscheme_light_variant = vim.env.COLOR_SCHEME_LIGHT_VARIANT,

    ---@type boolean
    enable_icons = false,

    ---@type boolean
    enable_statusline = true,

    ---@type "netrw" | "oil"
    file_explorer = "oil",

    ---@type number
    formatting_timeout_ms = 3000,
    icons = {
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
    },

    ---@type "telescope"
    picker = "telescope",

    ---@type boolean
    prettier_needs_config = false,
}

return M
