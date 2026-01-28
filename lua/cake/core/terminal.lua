local M = {}

local state = require "cake.state"

---Returns shell info for the given terminal
---@param terminal? string
---@return {path: string, flag: string, sep: string}
function M.get_shell_info(terminal)
  local shell = terminal or state.config.terminal
  if shell == nil or shell == "" then shell = vim.o.shell end

  local lower = shell:lower()
  local info = {
    path = shell,
    flag = "-c",
    sep = "\n",
  }

  if lower:find "powershell" or lower:find "pwsh" then
    info.flag = "-Command"
  elseif lower:find "cmd" then
    info.flag = "/c"
    info.sep = " && "
  end

  return info
end

---Initializes terminal for the active tab
function M.init()
  local session = require "cake.core.session"
  local tabs = require "cake.core.tabs"
  local utils = require "cake.utils"

  if #state.tabs == 0 then
    local saved_tabs = session.load_tabs()
    if #saved_tabs > 0 then
      for _, saved in ipairs(saved_tabs) do
        tabs.create { cwd = saved.cwd, commands = saved.commands or {} }
      end
    else
      tabs.create { cwd = state.cwd or vim.fn.getcwd() }
    end
  else
    for _, tab in ipairs(state.tabs) do
      if not tab.buf or not vim.api.nvim_buf_is_valid(tab.buf) then
        tab.buf = vim.api.nvim_create_buf(false, true)
      end
    end
  end

  local tab = state.tabs[state.active_tab]
  if tab then
    state.term.buf = tab.buf
    state.cwd = tab.cwd
  end

  require "cake.mappings"(state.term.buf, "term")
end

---Execute a command in a buffer, converting it to a terminal
---@param buf integer
---@param cmd string|string[]|nil
---@param terminal? string
---@param cwd? string
function M.run_in_buf(buf, cmd, terminal, cwd)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.bo[buf].buftype == "terminal" then return end

  local shell_info = M.get_shell_info(terminal)
  local final_cmd = cmd

  if type(cmd) == "table" then
    if #cmd == 0 then
      final_cmd = nil
    else
      final_cmd = table.concat(cmd, shell_info.sep)
    end
  end

  local job_cmd
  if final_cmd and final_cmd ~= "" then
    job_cmd = { shell_info.path, shell_info.flag, final_cmd }
  else
    job_cmd = shell_info.path
  end

  vim.api.nvim_buf_call(buf, function()
    local valid_cwd = cwd
    if not valid_cwd or vim.fn.isdirectory(valid_cwd) ~= 1 then
      valid_cwd = vim.fn.getcwd()
    end

    state.term.job_id = vim.fn.jobstart(job_cmd, {
      term = true,
      cwd = valid_cwd,
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            require "cake.mappings"(buf, "term")
          end
        end)
      end,
    })
  end)
end

---Resets the current tab's terminal buffer (for rerun)
function M.reset_buf()
  local tab = state.tabs[state.active_tab]
  if tab and tab.buf and vim.api.nvim_buf_is_valid(tab.buf) then
    vim.api.nvim_buf_delete(tab.buf, { force = true })
    tab.buf = vim.api.nvim_create_buf(false, true)
    state.term.buf = tab.buf
  end
end

---Sets up cursor events for a buffer to update the footer
---@param buf number
function M.setup_cursor_events(buf)
  local tabs = require "cake.core.tabs"
  local group =
    vim.api.nvim_create_augroup("CakeCursor" .. buf, { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = group,
    callback = function() tabs.redraw_footer() end,
  })

  vim.api.nvim_create_autocmd("TermEnter", {
    buffer = buf,
    group = group,
    callback = function()
      if state.footer.cursor_timer then
        state.footer.cursor_timer:stop()
      else
        state.footer.cursor_timer = vim.uv.new_timer()
      end

      state.footer.cursor_timer:start(
        0,
        100,
        vim.schedule_wrap(function()
          if
            state.header.win and vim.api.nvim_win_is_valid(state.header.win)
          then
            tabs.redraw_footer()
          else
            if state.footer.cursor_timer then
              state.footer.cursor_timer:stop()
              state.footer.cursor_timer = nil
            end
          end
        end)
      )
    end,
  })

  vim.api.nvim_create_autocmd({ "TermLeave", "BufLeave" }, {
    buffer = buf,
    group = group,
    callback = function()
      if state.footer.cursor_timer then
        state.footer.cursor_timer:stop()
        state.footer.cursor_timer = nil
      end
      tabs.redraw_footer()
    end,
  })
end

return M
