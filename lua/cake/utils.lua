local M = {}

local state = require "cake.state"

---Returns the current context CWD based on config
---@return string
function M.get_context_cwd()
  local context_win = state.prev_win or vim.api.nvim_get_current_win()
  local ok, context_buf = pcall(vim.api.nvim_win_get_buf, context_win)
  if not ok then context_buf = vim.api.nvim_get_current_buf() end

  local buftype =
    vim.api.nvim_get_option_value("buftype", { buf = context_buf })

  if state.config.use_file_dir and buftype ~= "terminal" then
    local path = vim.api.nvim_buf_get_name(context_buf)
    if path ~= "" then return vim.fn.fnamemodify(path, ":p:h") end
  end

  return vim.fn.getcwd()
end

return M
