---@class dot.Config
return {
    ---@type boolean
    autoformat = true,

    ---@type "native" | "nvim-cmp"
    cmp = "nvim-cmp",

    ---@type boolean
    enable_icons = false,

    ---@type "netrw" | "oil"
    file_explorer = "oil",

    ---@type integer
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
}
