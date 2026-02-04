vim.api.nvim_create_user_command(
  "CakeToggle",
  function() require("cake").toggle() end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeFloat",
  function() require("cake").open_float() end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitH",
  function() require("cake").open_split_h() end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitV",
  function() require("cake").open_split_v() end,
  {}
)
