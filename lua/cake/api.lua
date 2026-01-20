local M = {}

local state = require "cake.state"

M.cake_float = function() require("cake.ui").open() end


M.edit_cmds = function()
  state.resetting = true
  require("cake.edit").open()
end

---initializes terminal for the active tab
M.init_term = function()
  local utils = require "cake.utils"

  if #state.tabs == 0 then
    local saved_tabs = utils.load_tabs()
    if #saved_tabs > 0 then
      for _, saved in ipairs(saved_tabs) do
        M.create_tab { cwd = saved.cwd, commands = saved.commands or {} }
      end
    else
      M.create_tab { cwd = state.cwd or vim.fn.getcwd() }
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

  M.setup_term_keymaps(state.term.buf)
end

---creates a new tab and adds it to the list
---@param opts table? options: { cwd, commands }
---@return table|nil
M.create_tab = function(opts)
  if #state.tabs >= 9 then
    vim.notify("Maximum of 9 tabs reached!", vim.log.levels.WARN)
    return nil
  end

  opts = opts or {}
  local new_buf = vim.api.nvim_create_buf(false, true)
  local cwd = opts.cwd or vim.fn.getcwd()
  local id = #state.tabs + 1

  local tab = {
    id = id,
    buf = new_buf,
    cwd = cwd,
    commands = opts.commands or {},
  }

  table.insert(state.tabs, tab)
  return tab
end

---switches to a tab by index
---@param idx number tab index to switch to
M.switch_tab = function(idx)
  if idx < 1 or idx > #state.tabs then
    print("Tab " .. idx .. " does not exist!")
    return
  end

  state.active_tab = idx
  local tab = state.tabs[idx]
  if not tab then return end

  state.term.buf = tab.buf
  state.cwd = tab.cwd

  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_set_buf(state.term.win, state.term.buf)

    -- if buffer is not a terminal yet, run commands
    if vim.bo[state.term.buf].buftype ~= "terminal" then
      local cmds = tab.commands or {}
      M.cake_in_buf(state.term.buf, cmds, state.config.terminal, tab.cwd)
    end
    M.setup_term_keymaps(state.term.buf)

    vim.schedule(function()
      if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
        vim.api.nvim_set_current_win(state.term.win)
      end
    end)
  end

  -- redraw header
  M.redraw_header()
  M.redraw_footer()
end

---switches to the next tab
M.next_tab = function()
  if #state.tabs <= 1 then return end
  local next_idx = state.active_tab + 1
  if next_idx > #state.tabs then next_idx = 1 end
  M.switch_tab(next_idx)
end

---switches to the previous tab
M.prev_tab = function()
  if #state.tabs <= 1 then return end
  local prev_idx = state.active_tab - 1
  if prev_idx < 1 then prev_idx = #state.tabs end
  M.switch_tab(prev_idx)
end

---saves the current session as the active tab
M.save_current_tab = function()
  local utils = require "cake.utils"
  if #state.tabs == 0 then
    print "No tabs to save!"
    return
  end

  local tab = state.tabs[state.active_tab]
  if tab then
    tab.cwd = state.cwd or vim.fn.getcwd()
    utils.save_tabs()
    print("Tab " .. state.active_tab .. " saved!")
  end
end

---kills/deletes a tab by index
---@param idx number? tab index to kill (defaults to active)
M.kill_tab = function(idx)
  local utils = require "cake.utils"
  idx = idx or state.active_tab
  if idx < 1 or idx > #state.tabs then return end

  local tab_to_kill = state.tabs[idx]
  local new_tab = nil
  local new_active_idx = idx

  -- determine next tab
  if #state.tabs > 1 then
    if idx == #state.tabs then new_active_idx = idx - 1 end

    if idx == #state.tabs then
      new_tab = state.tabs[idx - 1]
    else
      new_tab = state.tabs[idx + 1]
    end
  else
    -- creating a tab if killing the only one
    new_tab = M.create_tab { cwd = state.cwd or vim.fn.getcwd() }
    new_active_idx = 1
  end

  if not new_tab then return end

  -- switch window to new buffer immediately
  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_set_buf(state.term.win, new_tab.buf)

    -- initialize the new buffer if needed
    if vim.bo[new_tab.buf].buftype ~= "terminal" then
      local cmds = new_tab.commands or {}
      M.cake_in_buf(new_tab.buf, cmds, state.config.terminal, new_tab.cwd)
    end
    M.setup_term_keymaps(new_tab.buf)
  end

  -- now safely delete the old buffer
  if
    tab_to_kill.buf
    and vim.api.nvim_buf_is_valid(tab_to_kill.buf)
    and tab_to_kill.buf ~= new_tab.buf
  then
    vim.api.nvim_buf_delete(tab_to_kill.buf, { force = true })
  end

  -- update state.tabs and active_tab
  if #state.tabs > 1 then
    table.remove(state.tabs, idx)
    state.active_tab = new_active_idx
  else
    table.remove(state.tabs, 1)
    state.active_tab = 1
  end

  -- update current state refs
  state.term.buf = new_tab.buf
  state.cwd = new_tab.cwd

  utils.save_tabs()
  M.redraw_header()
  print "Tab killed!"
end

---redraws the header to reflect tab changes
M.redraw_header = function()
  local volt = require "volt"
  if state.volt_buf and vim.api.nvim_buf_is_valid(state.volt_buf) then
    volt.redraw(state.volt_buf, "header")
  end
  if state.edit.volt_buf and vim.api.nvim_buf_is_valid(state.edit.volt_buf) then
    volt.redraw(state.edit.volt_buf, "header")
  end
end

---redraws the footer to reflect cursor changes
M.redraw_footer = function()
  local volt = require "volt"
  if state.footer.buf and vim.api.nvim_buf_is_valid(state.footer.buf) then
    volt.redraw(state.footer.buf, "footer")
  end
  if
    state.edit.footer_buf and vim.api.nvim_buf_is_valid(state.edit.footer_buf)
  then
    volt.redraw(state.edit.footer_buf, "edit_footer")
  end
end

---sets up cursor events for a buffer to update the footer
---@param buf number
M.setup_cursor_events = function(buf)
  local group =
    vim.api.nvim_create_augroup("CakeCursor" .. buf, { clear = true })

  -- normal mode updates
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = group,
    callback = function() M.redraw_footer() end,
  })

  -- terminal mode updates (requires polling as no events fire)
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
          if state.win and vim.api.nvim_win_is_valid(state.win) then
            M.redraw_footer()
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
      M.redraw_footer()
    end,
  })
end

---execute a command in a buffer, converting it to a terminal
---@param buf integer buffer number
---@param cmd string|table|nil command to execute (if nil, opens a terminal)
---@param terminal string|nil custom terminal executable
---@param cwd string|nil directory to execute in
M.cake_in_buf = function(buf, cmd, terminal, cwd)
  local utils = require "cake.utils"
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  if vim.bo[buf].buftype == "terminal" then return end

  local shell_info = utils.get_shell_info(terminal)
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
            M.setup_term_keymaps(buf)
          end
        end)
      end,
    })
  end)
end

---resets the current tab's terminal buffer (for rerun)
M.reset_buf = function()
  local tab = state.tabs[state.active_tab]
  if tab and tab.buf and vim.api.nvim_buf_is_valid(tab.buf) then
    vim.api.nvim_buf_delete(tab.buf, { force = true })

    tab.buf = vim.api.nvim_create_buf(false, true)
    state.term.buf = tab.buf
  end
end

---sets up keymaps for a terminal buffer
---@param buf number buffer to set keymaps on
M.setup_term_keymaps = function(buf)
  local utils = require "cake.utils"
  local m = state.config.mappings
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set("n", m.edit_commands, function() M.edit_cmds() end, opts)

  -- escape to toggle/close UI (Normal mode)
  vim.keymap.set("n", "<Esc>", function() require("cake").toggle() end, opts)

  vim.keymap.set("n", m.new_tab, function()
    if #state.tabs >= 9 then
      vim.notify("Maximum of 9 tabs reached!", vim.log.levels.WARN)
      return
    end

    state.resetting = true
    local tab = M.create_tab { cwd = utils.get_context_cwd() }
    if not tab then return end

    state.active_tab = #state.tabs
    state.term.buf = tab.buf

    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_win_set_buf(state.term.win, state.term.buf)
      M.cake_in_buf(state.term.buf, nil, state.config.terminal, tab.cwd)
    end

    M.setup_term_keymaps(state.term.buf)
    M.redraw_header()
  end, opts)

  vim.api.nvim_buf_call(buf, function()
    vim.cmd "cnoreabbrev <expr> <buffer> w getcmdtype() == ':' && getcmdline() ==# 'w' ? 'lua require\"cake.api\".save_current_tab()' : 'w'"
    vim.cmd "cnoreabbrev <expr> <buffer> w! getcmdtype() == ':' && getcmdline() ==# 'w!' ? 'lua require\"cake.api\".save_current_tab()' : 'w!'"
    vim.cmd "cnoreabbrev <expr> <buffer> write getcmdtype() == ':' && getcmdline() ==# 'write' ? 'lua require\"cake.api\".save_current_tab()' : 'write'"
  end)

  -- kill current tab
  vim.keymap.set("n", m.kill_tab, function() M.kill_tab() end, opts)

  -- rerun commands
  vim.keymap.set("n", m.rerun, function()
    local tab = state.tabs[state.active_tab]
    if tab and tab.commands and #tab.commands > 0 then
      state.resetting = true
      require("cake").open { reset = true }
    else
      print "No commands to rerun!"
    end
  end, opts)

  -- next/prev tab
  vim.keymap.set("n", m.next_tab, function() M.next_tab() end, opts)
  vim.keymap.set("n", m.prev_tab, function() M.prev_tab() end, opts)

  -- tab switching (1-9)
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function() M.switch_tab(i) end, opts)
  end

  M.setup_cursor_events(buf)

  -- help
  vim.keymap.set("n", "?", function() require("cake.help").open() end, opts)

  -- escape in terminal mode
  vim.keymap.set(
    "t",
    "<Esc>",
    [[<C-\><C-n>]],
    { buffer = buf, noremap = true, silent = true, nowait = true }
  )
end

return M
