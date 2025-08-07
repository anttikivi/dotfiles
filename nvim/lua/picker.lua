local config = require("config")

local M = {}

local function setup_telescope()
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
        vim.notify("Failed to load fzf extension for telescope", vim.log.levels.WARN)
    end

    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume picker" })
end

function M.pack_spec()
    if config.picker == "telescope" then
        return {
            { src = "https://github.com/nvim-telescope/telescope.nvim" },
            { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
        }
    else
        vim.notify(("Invalid picker %q"):format(config.picker), vim.log.levels.ERROR)
    end
end

function M.setup()
    if config.picker == "telescope" then
        setup_telescope()
    end
end

return M
