local map = vim.keymap.set
local api = require "exec.api"

return function()
  map(
    "n",
    "<leader>ef",
    function() require("exec").open { mode = "float", reset = true } end
  )
  map(
    "n",
    "<leader>es",
    function() require("exec").open { mode = "split", reset = true } end
  )
end
