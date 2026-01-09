local M = {}

---Execute a command in a buffer, converting it to a terminal if needed
---@param buf integer Buffer number
---@param cmd string|nil Command to execute (if nil, opens a terminal)
M.exec_in_buf = function(buf, cmd)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  -- Use termopen which automatically sets buftype to terminal
  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen(cmd or vim.o.shell)
  end)
end

return M
