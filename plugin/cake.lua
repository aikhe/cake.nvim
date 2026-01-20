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

-- TODO
-- vim.api.nvim_create_user_command(
--   "CakeSplit",
--   function() require("cake").open_split() end,
--   {}
-- )
