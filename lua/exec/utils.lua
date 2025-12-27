local M = {}

local api = vim.api
local state = require "exec.state"

M.reset_buf = function()
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
    state.buf = nil
  end
end

M.new_term = function()
  state.buf = state.buf or api.nvim_create_buf(false, true)

  M.exec_in_buf(state.buf, state.config.cmd, state.config.terminal)
end

---Execute a command in a buffer, converting it to a terminal if needed
---@param buf integer Buffer number
---@param cmd string|table|nil Command to execute (if nil, opens a terminal)
---@param terminal string|nil Custom terminal executable
M.exec_in_buf = function(buf, cmd, terminal)
  if not buf or not api.nvim_buf_is_valid(buf) then return end

  if vim.bo[buf].buftype == "terminal" then return end

  local final_cmd = cmd
  if type(cmd) == "table" then final_cmd = table.concat(cmd, " && ") end

  api.nvim_buf_call(
    buf,
    function()
      vim.fn.jobstart(final_cmd or terminal or vim.o.shell, {
        term = true,
      })
    end
  )
end

return M
