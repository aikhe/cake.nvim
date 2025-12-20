local M = {}

local state = require("exec.state")

M.setup = function(opts)
	state.config = vim.tbl_deep_extend("force", state.config, opts or {})

	if state.mapping then
		require("exec.mappings")()
	end
end

M.open = function()
	print("open exec")
end

M.toggle = function()
	print("toggle exec")
end

return M
