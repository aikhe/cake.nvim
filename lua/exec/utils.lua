local M = {}

local api = vim.api
local state = require "exec.state"

M.reset_buf = function()
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf = nil
end

M.new_term = function()
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    state.buf = api.nvim_create_buf(false, true)

    -- api.nvim_set_option_value("buflisted", false, { buf = state.buf })
    -- api.nvim_set_option_value("bufhidden", "hide", { buf = state.buf })
  end

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
  if type(cmd) == "table" then
    local sep = " && "
    local term_check = terminal or state.config.terminal or vim.o.shell
    if term_check:find "powershell" or term_check:find "pwsh" then
      sep = "; "
    end
    final_cmd = table.concat(cmd, sep)
  end

  local term = terminal or state.config.terminal or vim.o.shell
  local job_cmd

  if final_cmd then
    local flag = "-c"

    if term:find "powershell" or term:find "pwsh" then
      flag = "-Command"
    elseif term:find "cmd" then
      flag = "/c"
    end

    job_cmd = { term, flag, final_cmd }
  else
    job_cmd = term
  end

  api.nvim_buf_call(buf, function()
    vim.fn.jobstart(job_cmd, {
      term = true,
      on_exit = function()
        vim.schedule(function()
          if api.nvim_buf_is_valid(buf) then
            local keys =
              { "i", "I", "a", "A", "o", "O", "r", "R", "c", "C", "s", "S" }
            for _, key in ipairs(keys) do
              vim.keymap.set("n", key, "<Nop>", { buffer = buf, nowait = true })
            end
          end
        end)
      end,
    })
  end)
end

return M
