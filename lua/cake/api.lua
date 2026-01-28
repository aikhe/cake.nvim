local M = {}

local state = require "cake.state"
local tabs = require "cake.core.tabs"
local terminal = require "cake.core.terminal"
local session = require "cake.core.session"

-- UI entry points
M.cake_float = function() require("cake.ui").open() end
M.edit_cmds = function()
  state.resetting = true
  require("cake.ui.edit").open()
end

-- Tab operations
M.init_term = terminal.init
M.create_tab = tabs.create
M.switch_tab = tabs.switch
M.next_tab = tabs.next
M.prev_tab = tabs.prev
M.kill_tab = tabs.kill
M.save_current_tab = tabs.save_current
M.redraw_header = tabs.redraw_header
M.redraw_footer = tabs.redraw_footer

-- Terminal operations
M.cake_in_buf = terminal.run_in_buf
M.reset_buf = terminal.reset_buf
M.setup_cursor_events = terminal.setup_cursor_events

-- Session operations
M.load_tabs = session.load_tabs
M.save_tabs = session.save_tabs

return M
