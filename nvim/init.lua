if vim.loader then
  vim.loader.enable()
end

require("config.lazy").load()
require("filetypes")
