local config = require("dot.config")
local util = require("dot.util")

local M = {}

function M.setup()
    local specs = {}

    local path = vim.fn.stdpath("config") .. "/lua/dot/"
    local files = vim.fn.globpath(path, "*.lua", false, true)

    table.sort(files)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        if name ~= "init" then
            local module_name = "dot." .. name
            local ok, module = pcall(require, module_name)
            if ok then
                if type(module.pack_specs) == "function" then
                    vim.list_extend(specs, module.pack_specs())
                end
            else
                vim.notify(("[pack] failed to load %s: %s"):format(module_name, module), vim.log.levels.ERROR)
            end
        end
    end

    if config.picker == "telescope" then
        require("dot.picker").setup_telescope_fzf_autocmd()
    end

    vim.pack.add(specs)

    vim.api.nvim_create_autocmd("PackChanged", {
        group = util.augroup("pack_changed"),
        callback = function(ev)
            if ev.data.spec.name == "mason.nvim" then
                if ev.data.kind == "install" or ev.data.kind == "update" then
                    vim.cmd("MasonUpdate")
                end
            elseif ev.data.spec.name == "nvim-treesitter" then
                if ev.data.kind == "install" or ev.data.kind == "update" then
                    vim.cmd("TSUpdate")
                end
            end
        end,
    })

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
end

return M
