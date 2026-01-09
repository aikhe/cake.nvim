local M = {}

M.exec_float = function() require("exec").open("float") end
M.exec_split = function() require("exec").open("split") end
M.toggle = function() require("exec").toggle() end

return M
