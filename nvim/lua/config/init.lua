---@class Config
local M = {
    ---@type boolean
    autoformat = true,

    ---@type "catppuccin" | "rose-pine" | "tokyonight"
    colorscheme = vim.env.COLOR_SCHEME,

    ---@type "frappe" | "macchiato" | "mocha" | "main" | "moon" | "storm" | "night"
    colorscheme_dark_variant = vim.env.COLOR_SCHEME_DARK_VARIANT,

    ---@type "latte" | "dawn" | "day"
    colorscheme_light_variant = vim.env.COLOR_SCHEME_LIGHT_VARIANT,

    ---@type "default" | "netrw" | "oil"
    file_explorer = "oil",

    ---@type number
    formatting_timeout_ms = 3000,
}

-- Why I do this? I don't know.
if M.file_explorer == "default" then
    M.file_explorer = "netrw"
end

return M
