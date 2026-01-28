local M = {}

local state = require "cake.state"

---Creates a new tab and adds it to the list
---@param opts? {cwd?: string, commands?: string[]}
---@return CakeTab|nil
function M.create(opts)
  if #state.tabs >= 9 then
    vim.notify("Maximum of 9 tabs reached!", vim.log.levels.WARN)
    return nil
  end

  opts = opts or {}
  local new_buf = vim.api.nvim_create_buf(false, true)
  local cwd = opts.cwd or vim.fn.getcwd()
  local id = #state.tabs + 1

  ---@type CakeTab
  local tab = {
    id = id,
    buf = new_buf,
    cwd = cwd,
    commands = opts.commands or {},
  }

  table.insert(state.tabs, tab)
  return tab
end

---Creates a new tab from current context and switches to it
function M.create_new()
  if #state.tabs >= 9 then
    vim.notify("Maximum of 9 tabs reached!", vim.log.levels.WARN)
    return
  end

  state.resetting = true
  local utils = require "cake.utils"
  local tab = M.create { cwd = utils.get_context_cwd() }
  if not tab then return end

  state.active_tab = #state.tabs
  state.term.buf = tab.buf

  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_set_buf(state.term.win, state.term.buf)
    require("cake.core.terminal").run_in_buf(
      state.term.buf,
      nil,
      state.config.terminal,
      tab.cwd
    )
  end

  require "cake.mappings"(state.term.buf, "term")
  M.redraw_header()
end

---Switches to a tab by index
---@param idx number
function M.switch(idx)
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

    if vim.bo[state.term.buf].buftype ~= "terminal" then
      local cmds = tab.commands or {}
      require("cake.core.terminal").run_in_buf(
        state.term.buf,
        cmds,
        state.config.terminal,
        tab.cwd
      )
    end
    require "cake.mappings"(state.term.buf, "term")

    vim.schedule(function()
      if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
        vim.api.nvim_set_current_win(state.term.win)
      end
    end)
  end

  M.redraw_header()
  M.redraw_footer()
end

---Switches to the next tab
function M.next()
  if #state.tabs <= 1 then return end
  local next_idx = state.active_tab + 1
  if next_idx > #state.tabs then next_idx = 1 end
  M.switch(next_idx)
end

---Switches to the previous tab
function M.prev()
  if #state.tabs <= 1 then return end
  local prev_idx = state.active_tab - 1
  if prev_idx < 1 then prev_idx = #state.tabs end
  M.switch(prev_idx)
end

---Saves the current session as the active tab
function M.save_current()
  local session = require "cake.core.session"
  if #state.tabs == 0 then
    print "No tabs to save!"
    return
  end

  local tab = state.tabs[state.active_tab]
  if tab then
    tab.cwd = state.cwd or vim.fn.getcwd()
    session.save_tabs()
    print("Tab " .. state.active_tab .. " saved!")
  end
end

---Kills/deletes a tab by index
---@param idx? number
function M.kill(idx)
  local session = require "cake.core.session"
  local terminal = require "cake.core.terminal"

  idx = idx or state.active_tab
  if idx < 1 or idx > #state.tabs then return end

  local tab_to_kill = state.tabs[idx]
  local new_tab = nil
  local new_active_idx = idx

  if #state.tabs > 1 then
    if idx == #state.tabs then new_active_idx = idx - 1 end
    new_tab = idx == #state.tabs and state.tabs[idx - 1] or state.tabs[idx + 1]
  else
    new_tab = M.create { cwd = state.cwd or vim.fn.getcwd() }
    new_active_idx = 1
  end

  if not new_tab then return end

  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_set_buf(state.term.win, new_tab.buf)

    if vim.bo[new_tab.buf].buftype ~= "terminal" then
      local cmds = new_tab.commands or {}
      terminal.run_in_buf(new_tab.buf, cmds, state.config.terminal, new_tab.cwd)
    end
    require "cake.mappings"(new_tab.buf, "term")
  end

  if
    tab_to_kill.buf
    and vim.api.nvim_buf_is_valid(tab_to_kill.buf)
    and tab_to_kill.buf ~= new_tab.buf
  then
    vim.api.nvim_buf_delete(tab_to_kill.buf, { force = true })
  end

  if #state.tabs > 1 then
    table.remove(state.tabs, idx)
    state.active_tab = new_active_idx
  else
    table.remove(state.tabs, 1)
    state.active_tab = 1
  end

  state.term.buf = new_tab.buf
  state.cwd = new_tab.cwd

  session.save_tabs()
  M.redraw_header()
  print "Tab killed!"
end

---Redraws the header to reflect tab changes
function M.redraw_header()
  local volt = require "volt"
  if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
    volt.redraw(state.header.buf, "header")
  end
  if
    state.edit.header_buf and vim.api.nvim_buf_is_valid(state.edit.header_buf)
  then
    volt.redraw(state.edit.header_buf, "header")
  end
end

---Redraws the footer to reflect cursor changes
function M.redraw_footer()
  local volt = require "volt"
  if state.footer.buf and vim.api.nvim_buf_is_valid(state.footer.buf) then
    volt.redraw(state.footer.buf, "footer")
  end
  if
    state.edit.footer_buf and vim.api.nvim_buf_is_valid(state.edit.footer_buf)
  then
    volt.redraw(state.edit.footer_buf, "footer")
  end
end

return M
