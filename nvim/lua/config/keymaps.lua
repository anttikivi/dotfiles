-- Make up and down take line wrapping into account.
vim.keymap.set(
  { "n", "x" },
  "j",
  "v:count == 0 ? 'gj' : 'j'",
  { desc = "Down", expr = true, silent = true }
)
vim.keymap.set(
  { "n", "x" },
  "k",
  "v:count == 0 ? 'gk' : 'k'",
  { desc = "Up", expr = true, silent = true }
)

-- Go to the file explorer.
vim.keymap.set(
  "n",
  "<leader>e",
  vim.cmd.Ex,
  { desc = "Resume to file explorer" }
)

-- Clear highlights on search and stop snippets.
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  require("util.cmp").actions.snippet_stop()
  return "<esc>"
end, { expr = true, desc = "Clear highlights and stop snippet" })

-- Better indenting.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Diagnostic keymaps
vim.keymap.set(
  "n",
  "<leader>cd",
  vim.diagnostic.open_float,
  { desc = "Line diagnostics" }
)

-- Paste without overwriting the clipboard.
vim.keymap.set(
  "x",
  "<leader>p",
  [["_dP]],
  { desc = "Paste without overwriting the clipboard" }
)

-- Delete without yanking.
vim.keymap.set(
  { "n", "v" },
  "<leader>d",
  [["_d]],
  { desc = "Delete without yanking" }
)

-- Make a file executable.
vim.keymap.set(
  "n",
  "<leader>x",
  [[:!chmod +x %<CR>]],
  { desc = "Make file executable" }
)

-- Various commands
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })
vim.keymap.set("n", "<leader>M", "<cmd>Mason<cr>", { desc = "Mason" })
