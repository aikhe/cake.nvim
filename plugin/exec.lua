vim.api.nvim_create_user_command(
  "Exec",
  function() require("exec").toggle() end,
  {}
)

vim.keymap.set(
  "n",
  "<leader>et",
  function() require("exec").toggle() end,
  { desc = "Toggle exec" }
)
