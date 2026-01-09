local M = {
	mapping = true,
	mode = nil,
	prev_win = nil,
	buf = nil,
	win = nil,
	config = {
		border = "single",
		size = {
			h = 50, -- height percentage
			w = 80, -- width percentage
		},
		cmd = nil, -- command to execute (nil = open shell)
		split_direction = "split", -- "split" or "vsplit"
		split_size = nil, -- size in lines for split window
	},
}

return M
