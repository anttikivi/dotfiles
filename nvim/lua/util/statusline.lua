local M = {}

function M.get()
  local parts = {}

  table.insert(parts, "%#StatusLineGit#")
  table.insert(
    parts,
    "%{luaeval('require(\"util.statusline\").get_git_branch()')}"
  )
  table.insert(parts, "%*")
  table.insert(parts, " %f")
  table.insert(parts, " %m")
  table.insert(parts, " %r")
  table.insert(parts, "%=")
  table.insert(parts, " ")
  table.insert(parts, "%y ")
  table.insert(parts, "%p%% ")
  table.insert(parts, "%l:%c")

  return table.concat(parts, "")
end

function M.get_git_branch()
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")

  if vim.v.shell_error ~= 0 then
    return ""
  end

  branch = branch:gsub("%s+", "")
  if branch == "" then
    return ""
  end

  return " " .. branch
end

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "StatusLineGit", { link = "Identifier" })
end

return M
