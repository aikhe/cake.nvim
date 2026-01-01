local M = {}

local api = vim.api
local state = require "exec.state"

M.new_term = function()
  state.buf = state.buf or api.nvim_create_buf(false, true)

  M.exec_in_buf(state.buf, state.config.cmd, state.config.terminal)
end

---Execute a command in a buffer, converting it to a terminal if needed
---@param buf integer Buffer number
---@param cmd string|nil Command to execute (if nil, opens a terminal)
---@param terminal string|nil Custom terminal executable
M.exec_in_buf = function(buf, cmd, terminal)
  if not buf or not api.nvim_buf_is_valid(buf) then return end

  if vim.bo[buf].buftype == "terminal" then return end

  api.nvim_buf_call(
    buf,
    function()
      vim.fn.jobstart(cmd or terminal or vim.o.shell, {
        term = true,
      })
    end
  )
end

return M
