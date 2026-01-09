local map = vim.keymap.set
local api = require "exec.api"

return function()
  map("n", "<leader>ef", api.exec_float)
  map("n", "<leader>es", api.exec_split)
  map("n", "<leader>et", api.toggle)
end
