local config = require("dot.config")
local util = require("dot.util")

local M = {}

function M.setup()
    if config.picker == "telescope" then
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
            vim.notify("failed to load fzf extension for telescope", vim.log.levels.WARN)
        end

        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
        vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume picker" })
    end
end

function M.setup_telescope_fzf_autocmd()
    vim.api.nvim_create_autocmd("PackChanged", {
        group = util.augroup("pack_changed"),
        callback = function(ev)
            if ev.data.spec.name ~= "telescope-fzf-native.nvim" then
                return
            end

            if ev.data.kind == "install" or ev.data.kind == "update" then
                if vim.fn.executable("cmake") == 1 then
                    local obj = vim.system({
                        "cmake",
                        "-S.",
                        "-Bbuild",
                        "-DCMAKE_BUILD_TYPE=Release",
                        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    }, { cwd = ev.data.path }):wait()

                    if obj.code ~= 0 then
                        vim.notify("failed to build telescope-fzf-native.nvim with CMake", vim.log.levels.ERROR)
                        vim.notify(obj.stderr, vim.log.levels.ERROR)

                        return
                    end

                    obj = vim.system({
                        "cmake",
                        "--build",
                        "build",
                        "--config",
                        "Release",
                    }, { cwd = ev.data.path }):wait()

                    if obj.code ~= 0 then
                        vim.notify("failed to build telescope-fzf-native.nvim with CMake", vim.log.levels.ERROR)
                        vim.notify(obj.stderr, vim.log.levels.ERROR)

                        return
                    end

                    vim.notify("built telescope-fzf-native.nvim", vim.log.levels.INFO)
                elseif vim.fn.executable("make") == 1 then
                    local obj = vim.system({ "make" }, { cwd = ev.data.path }):wait()

                    if obj.code ~= 0 then
                        vim.notify("failed to build telescope-fzf-native.nvim with make", vim.log.levels.ERROR)
                        vim.notify(obj.stderr, vim.log.levels.ERROR)

                        return
                    end

                    vim.notify("built telescope-fzf-native.nvim", vim.log.levels.INFO)
                else
                    vim.notify("cannot built telescope-fzf-native.nvim", vim.log.levels.ERROR)
                end
            end
        end,
    })
end

return M
