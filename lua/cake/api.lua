local M = {}

local state = require "cake.state"
local tabs = require "cake.core.tabs"
local terminal = require "cake.core.terminal"
local session = require "cake.core.session"
local ui = require "cake.ui"

-- ui entry points
M.cake_float = function() ui.open() end
M.cake_split_h = function() ui.split.open("horizontal") end
M.cake_split_v = function() ui.split.open("vertical") end
M.edit_cmds = function()
  state.resetting = true
  ui.edit.open()
end

-- tab operations
M.init_term = terminal.init
M.create_tab = tabs.create
M.switch_tab = tabs.switch
M.next_tab = tabs.next
M.prev_tab = tabs.prev
M.kill_tab = tabs.kill
M.save_current_tab = tabs.save_current
M.redraw_header = tabs.redraw_header
M.redraw_footer = tabs.redraw_footer

-- terminal operations
M.cake_in_buf = terminal.run_in_buf
M.reset_buf = terminal.reset_buf
M.setup_cursor_events = terminal.setup_cursor_events

-- session operations
M.load_tabs = session.load_tabs
M.save_tabs = session.save_tabs

return M
