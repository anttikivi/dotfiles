local M = {}

function M.get()
  local line = {}

  table.insert(line, "%<")

  -- The highlight group and value for the current Git branch
  table.insert(line, "%#StatusLineGitBranch#")
  table.insert(
    line,
    "%{luaeval('require(\"util.statusline\").branch_space()')}"
  )
  table.insert(line, "%{luaeval('require(\"util.statusline\").branch()')}")
  table.insert(line, "%*")

  -- File type
  table.insert(line, "%{%luaeval('require(\"util.statusline\").ft_icon()')%}")

  -- Current file and file flags
  table.insert(line, "%f %h%w%m%r")

  -- Section separation point
  table.insert(line, "%=")

  -- Line and column and the ruler
  table.insert(line, "%-14.(%l,%c%V%) %P")

  return table.concat(line, "")
end

M._git_branch = ""
M._git_buf = -1

function M.branch()
  return M._git_branch
end

function M.branch_space()
  return M._git_branch ~= "" and " " or ""
end

function M._update_git_branch()
  local buf = vim.api.nvim_get_current_buf()
  if buf == M._git_buf and M._git_branch ~= "" then
    return
  end

  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")

  if vim.v.shell_error ~= 0 then
    M._git_branch = ""
    M._git_buf = buf

    return
  end

  branch = branch:gsub("%s+", "")
  if branch == "" then
    M._git_branch = ""
    M._git_buf = buf

    return
  end

  -- Include the trailing space in the branch so there is no extra space when
  -- the branch is empty.
  M._git_branch = " " .. branch .. " "
  M._git_buf = buf
end

function M.ft_icon()
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return ""
  end

  local icon, icon_highlight_group = devicons.get_icon(vim.fn.expand("%:t"))
  if icon == nil then
    icon, icon_highlight_group = devicons.get_icon_by_filetype(vim.bo.filetype)
  end

  if icon == nil and icon_highlight_group == nil then
    icon = ""
    icon_highlight_group = "DevIconDefault"
  end

  return " %#" .. icon_highlight_group .. "#" .. icon .. "%* "
end

function M._set_highlights()
  if vim.g.colorscheme == "catppuccin" then
    local palette = require("catppuccin.palettes").get_palette(
      vim.o.background == "dark" and vim.g.colorscheme_dark_variant
        or vim.g.colorscheme_light_variant
    )

    vim.api.nvim_set_hl(
      0,
      "StatusLineGitBranch",
      { bg = palette.blue, fg = palette.mantle }
    )
  end

  vim.cmd("redrawstatus!")
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("git_cache", { clear = true }),
    callback = function()
      vim.schedule(function()
        M._update_git_branch()
        vim.cmd("redrawstatus!")
      end)
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("statusline_hl", { clear = true }),
    callback = function()
      M._set_highlights()
    end,
  })
  vim.schedule(M._update_git_branch)
  M._set_highlights()
end

return M
