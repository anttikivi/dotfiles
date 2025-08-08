local util = require("util")

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = util.augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank()
    end,
})

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local last_lsp_progress = 0

vim.api.nvim_create_autocmd("LspProgress", {
    group = util.augroup("lsp_progress"),
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

vim.api.nvim_create_autocmd("PackChanged", {
    group = util.augroup("mason_update"),
    callback = function(ev)
        if ev.data.spec.name ~= "mason.nvim" then
            return
        end
        if ev.data.kind == "install" or ev.data.kind == "update" then
            vim.cmd("MasonUpdate")
        end
    end,
})

vim.api.nvim_create_autocmd("PackChanged", {
    group = util.augroup("telescope_fzf_build"),
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
                    vim.notify("Failed to build telescope-fzf-native.nvim with CMake", vim.log.levels.ERROR)
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
                    vim.notify("Failed to build telescope-fzf-native.nvim with CMake", vim.log.levels.ERROR)
                    vim.notify(obj.stderr, vim.log.levels.ERROR)

                    return
                end

                vim.notify("Built telescope-fzf-native.nvim", vim.log.levels.INFO)
            elseif vim.fn.executable("make") == 1 then
                local obj = vim.system({ "make" }, { cwd = ev.data.path }):wait()

                if obj.code ~= 0 then
                    vim.notify("Failed to build telescope-fzf-native.nvim with make", vim.log.levels.ERROR)
                    vim.notify(obj.stderr, vim.log.levels.ERROR)

                    return
                end

                vim.notify("Built telescope-fzf-native.nvim", vim.log.levels.INFO)
            else
                vim.notify("Cannot built telescope-fzf-native.nvim", vim.log.levels.ERROR)
            end
        end
    end,
})

vim.api.nvim_create_autocmd("PackChanged", {
    group = util.augroup("treesitter_update"),
    callback = function(ev)
        if ev.data.spec.name ~= "nvim-treesitter" then
            return
        end
        if ev.data.kind == "install" or ev.data.kind == "update" then
            vim.cmd("TSUpdate")
        end
    end,
})
