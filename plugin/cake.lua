vim.api.nvim_create_user_command(
  "CakeToggle",
  function() require("cake").toggle() end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeFloat",
  function() require("cake").open { mode = "float" } end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitH",
  function() require("cake").open { mode = "splith" } end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitV",
  function() require("cake").open { mode = "splitv" } end,
  {}
)
