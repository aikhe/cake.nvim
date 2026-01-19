vim.api.nvim_create_user_command(
  "Exec",
  function() require("exec").toggle() end,
  {}
)

vim.api.nvim_create_user_command(
  "ExecFloat",
  function() require("exec").open_float() end,
  {}
)

vim.api.nvim_create_user_command(
  "ExecSplit",
  function() require("exec").open_split() end,
  {}
)

vim.api.nvim_create_user_command(
  "ExecSave",
  function() require("exec.api").save_current_tab() end,
  {}
)
