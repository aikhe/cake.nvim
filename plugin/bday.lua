vim.api.nvim_create_user_command(
  "BdayToggle",
  function() require("bday").toggle() end,
  {}
)

vim.api.nvim_create_user_command(
  "BdayFloat",
  function() require("bday").open_float() end,
  {}
)

-- vim.api.nvim_create_user_command(
--   "BdaySplit",
--   function() require("bday").open_split() end,
--   {}
-- )

-- vim.api.nvim_create_user_command(
--   "BdaySave",
--   function() require("bday.api").save_current_tab() end,
--   {}
-- )
