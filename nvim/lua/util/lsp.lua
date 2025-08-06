local M = {}

-- Register a function to be run with an autocommand when a language server attaches to a buffer.
---@param on_attach fun(client: vim.lsp.Client, buf: integer)
---@param name? string
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type integer
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        -- TODO: Modify if the function passed as a parameter should return a
        -- value.
        on_attach(client, buffer)
      end
    end,
  })
end

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
