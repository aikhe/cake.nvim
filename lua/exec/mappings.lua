local map = vim.keymap.set
local api = require "exec.api"

return function()
  map("n", "<leader>ef", require("exec").open_float)
  map("n", "<leader>es", require("exec").open_split)
end
