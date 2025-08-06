local M = {}

-- Really stupid cache but I guess it works for my needs.
local cached_server_names = {} ---@type string[]

---@return string[]
function M.server_names()
    if #cached_server_names == 0 then
        for name, type in vim.fs.dir(vim.fn.stdpath("config") .. "/lsp") do
            if type == "file" and name:sub(-4) == ".lua" then
                cached_server_names[#cached_server_names + 1] = name:gsub("%.lua$", "")
            end
        end
    end

    return cached_server_names
end

return M
