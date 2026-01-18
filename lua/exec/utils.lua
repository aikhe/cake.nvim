local M = {}

local api = vim.api
local state = require "exec.state"

---returns the path to the tabs save file
---@return string Path to the tabs file
M.get_tabs_path = function() return vim.fn.stdpath "data" .. "/exec_tabs.json" end

---loads tabs from the save file
---@return table List of tabs
M.load_tabs = function()
  local path = M.get_tabs_path()
  local f = io.open(path, "r")

  if f then
    local content = f:read "*a"
    f:close()

    if content and content ~= "" then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == "table" then return decoded end
    end
  end
  return {}
end

---saves the current tabs to save file
M.save_tabs = function()
  local path = M.get_tabs_path()
  local f = io.open(path, "w")

  if f then
    -- save cwd and commands per tab
    local save_data = {}
    for _, tab in ipairs(state.tabs) do
      table.insert(save_data, { cwd = tab.cwd, commands = tab.commands or {} })
    end
    f:write(vim.fn.json_encode(save_data))
    f:close()
  end
end

---creates a new tab and adds it to the list
---@param opts table? options: { cwd, commands }
---@return table
M.create_tab = function(opts)
  opts = opts or {}
  local new_buf = api.nvim_create_buf(false, true)
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
  state.term.buf = tab.buf
  state.cwd = tab.cwd

  if state.term.win and api.nvim_win_is_valid(state.term.win) then
    api.nvim_win_set_buf(state.term.win, state.term.buf)

    -- if buffer is fresh (not a terminal yet), run commands
    if vim.bo[state.term.buf].buftype ~= "terminal" then
      local cmds = tab.commands or {}
      M.exec_in_buf(state.term.buf, cmds, state.config.terminal, tab.cwd)
    end
    M.setup_term_keymaps(state.term.buf)

    vim.schedule(function()
      if state.term.win and api.nvim_win_is_valid(state.term.win) then
        api.nvim_set_current_win(state.term.win)
      end
    end)
  end

  -- redraw header
  M.redraw_header()
  M.redraw_footer()
end

---saves the current session as the active tab
M.save_current_tab = function()
  if #state.tabs == 0 then
    print "No tabs to save!"
    return
  end

  local tab = state.tabs[state.active_tab]
  if tab then
    tab.cwd = state.cwd or vim.fn.getcwd()
    M.save_tabs()
    print("Tab " .. state.active_tab .. " saved!")
  end
end

---kills/deletes a tab by index
---@param idx number? tab index to kill (defaults to active)
M.kill_tab = function(idx)
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

  -- switch window to new buffer immediately
  if state.term.win and api.nvim_win_is_valid(state.term.win) then
    api.nvim_win_set_buf(state.term.win, new_tab.buf)

    -- initialize the new buffer if needed
    if vim.bo[new_tab.buf].buftype ~= "terminal" then
      local cmds = new_tab.commands or {}
      M.exec_in_buf(new_tab.buf, cmds, state.config.terminal, new_tab.cwd)
    end
    M.setup_term_keymaps(new_tab.buf)
  end

  -- now safely delete the old buffer
  if
    tab_to_kill.buf
    and api.nvim_buf_is_valid(tab_to_kill.buf)
    and tab_to_kill.buf ~= new_tab.buf
  then
    api.nvim_buf_delete(tab_to_kill.buf, { force = true })
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

  M.save_tabs()
  M.redraw_header()
  print "Tab killed!"
end

---redraws the header to reflect tab changes
M.redraw_header = function()
  local volt = require "volt"
  if state.volt_buf and api.nvim_buf_is_valid(state.volt_buf) then
    volt.redraw(state.volt_buf, "header")
  end
  if state.edit.volt_buf and api.nvim_buf_is_valid(state.edit.volt_buf) then
    volt.redraw(state.edit.volt_buf, "edit_header")
  end
end

---redraws the footer to reflect cursor changes
M.redraw_footer = function()
  local volt = require "volt"
  if state.footer.buf and api.nvim_buf_is_valid(state.footer.buf) then
    volt.redraw(state.footer.buf, "footer")
  end
  if state.edit.footer_buf and api.nvim_buf_is_valid(state.edit.footer_buf) then
    volt.redraw(state.edit.footer_buf, "edit_footer")
  end
end

---sets up cursor events for a buffer to update the footer
---@param buf number
M.setup_cursor_events = function(buf)
  local group = api.nvim_create_augroup("ExecCursor" .. buf, { clear = true })

  -- normal mode updates
  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = group,
    callback = function() M.redraw_footer() end,
  })

  -- terminal mode updates (requires polling as no events fire)
  api.nvim_create_autocmd("TermEnter", {
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
          if state.win and api.nvim_win_is_valid(state.win) then
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

  api.nvim_create_autocmd({ "TermLeave", "BufLeave" }, {
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

---returns the path to the commands JSON file
---@return string path to the commands file
M.get_cmds_path = function()
  return vim.fn.stdpath "data" .. "/exec_commands.json"
end

---loads commands from the persistent JSON file
---@return table list of commands
M.load_commands = function()
  local path = M.get_cmds_path()
  local f = io.open(path, "r")

  if f then
    local content = f:read "*a"
    f:close()

    if content then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == "table" then return decoded end
    end
  end
  return {}
end

---saves the current list of commands to the persistent JSON file
---@param cmds table list of commands to save
M.save_commands = function(cmds)
  local path = M.get_cmds_path()
  local f = io.open(path, "w")

  if f then
    f:write(vim.fn.json_encode(cmds))
    f:close()
  end
end

---sets up keymaps for a terminal buffer
---@param buf number buffer to set keymaps on
M.setup_term_keymaps = function(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set(
    "n",
    state.config.edit_key,
    function() require("exec.api").edit_cmds() end,
    opts
  )

  vim.keymap.set("n", "n", function()
    state.resetting = true
    local tab = M.create_tab { cwd = state.cwd }
    state.active_tab = #state.tabs
    state.term.buf = tab.buf

    if state.term.win and api.nvim_win_is_valid(state.term.win) then
      api.nvim_win_set_buf(state.term.win, state.term.buf)
      M.exec_in_buf(state.term.buf, nil, state.config.terminal, tab.cwd)
    end

    M.setup_term_keymaps(state.term.buf)
    M.redraw_header()
  end, opts)

  -- saving
  api.nvim_buf_create_user_command(
    buf,
    "ExecSave",
    function() M.save_current_tab() end,
    {}
  )

  local abbrev_cmd =
    "cnoreabbrev <expr> <buffer> w getcmdtype() == ':' && getcmdline() == 'w' ? 'ExecSave' : 'w'"
  vim.cmd(abbrev_cmd)
  vim.cmd "cnoreabbrev <expr> <buffer> write getcmdtype() == ':' && getcmdline() == 'write' ? 'ExecSave' : 'write'"

  -- kill current tab
  vim.keymap.set("n", "x", function() M.kill_tab() end, opts)

  -- rerun commands
  vim.keymap.set("n", "r", function()
    local tab = state.tabs[state.active_tab]
    if tab and tab.commands and #tab.commands > 0 then
      state.resetting = true
      require("exec").open { reset = true }
    else
      print "No commands to rerun!"
    end
  end, opts)

  -- tab switching (1-9)
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function() M.switch_tab(i) end, opts)
  end

  M.setup_cursor_events(buf)

  -- help
  vim.keymap.set("n", "?", function() require("exec.ui.help").open() end, opts)

  -- escape in terminal mode
  vim.keymap.set(
    "t",
    "<Esc>",
    [[<C-\><C-n>]],
    { buffer = buf, noremap = true, silent = true, nowait = true }
  )
end

---initializes terminal for the active tab
M.init_term = function()
  -- load persisted tabs or create first one
  if #state.tabs == 0 then
    local saved_tabs = M.load_tabs()
    if #saved_tabs > 0 then
      -- restore saved tabs (create new buffers for each)
      for _, saved in ipairs(saved_tabs) do
        M.create_tab { cwd = saved.cwd, commands = saved.commands or {} }
      end
    else
      -- first time: create initial tab with no commands
      M.create_tab { cwd = state.cwd or vim.fn.getcwd() }
    end
  else
    -- ensure all existing tabs have valid buffers (resurrect if killed)
    for _, tab in ipairs(state.tabs) do
      if not tab.buf or not api.nvim_buf_is_valid(tab.buf) then
        tab.buf = api.nvim_create_buf(false, true)
      end
    end
  end

  -- set active tab's buffer as current
  local tab = state.tabs[state.active_tab]
  if tab then
    state.term.buf = tab.buf
    state.cwd = tab.cwd
  end

  M.setup_term_keymaps(state.term.buf)
end

---execute a command in a buffer, converting it to a terminal
---@param buf integer buffer number
---@param cmd string|table|nil command to execute (if nil, opens a terminal)
---@param terminal string|nil custom terminal executable
---@param cwd string|nil directory to execute in
M.exec_in_buf = function(buf, cmd, terminal, cwd)
  if not buf or not api.nvim_buf_is_valid(buf) then return end

  if vim.bo[buf].buftype == "terminal" then return end

  local final_cmd = cmd
  if type(cmd) == "table" then
    if #cmd == 0 then
      final_cmd = nil
    else
      local sep = " && "
      local term_check = terminal or state.config.terminal or vim.o.shell
      if term_check:find "powershell" or term_check:find "pwsh" then
        sep = "; "
      end
      final_cmd = table.concat(cmd, sep)
    end
  end

  local term = terminal or state.config.terminal or vim.o.shell
  local job_cmd

  if final_cmd and final_cmd ~= "" then
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
    state.term.job_id = vim.fn.jobstart(job_cmd, {
      term = true,
      cwd = cwd,
      on_exit = function()
        vim.schedule(function()
          if api.nvim_buf_is_valid(buf) then
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            M.setup_term_keymaps(buf)

            vim.keymap.set(
              "n",
              "<Esc>",
              function() require("exec").toggle() end,
              { buffer = buf, noremap = true, silent = true }
            )
          end
        end)
      end,
    })
  end)
end

---resets the current tab's terminal buffer (for rerun)
M.reset_buf = function()
  local tab = state.tabs[state.active_tab]
  if tab and tab.buf and api.nvim_buf_is_valid(tab.buf) then
    api.nvim_buf_delete(tab.buf, { force = true })

    tab.buf = api.nvim_create_buf(false, true)
    state.term.buf = tab.buf
  end
end

return M
