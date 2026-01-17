local state = require "exec.state"

local M = {}

---Renders tab numbers in header (simple text like nav)
M.tabs = function()
  local line = {}
  local num_icons = {
    "󰎤",
    "󰎧",
    "󰎪",
    "󰎭",
    "󰎱",
    "󰎳",
    "󰎶",
    "󰎹",
    "󰎼",
  }

  if #state.tabs == 0 then
    -- No tabs yet, show placeholder
    local icon = num_icons[1] or "1"
    table.insert(line, { icon .. " ", "ExecTabActive" })
  else
    for i, _ in ipairs(state.tabs) do
      local is_active = (i == state.active_tab)
      local hl = is_active and "ExecTabActive" or "ExecTabInactive"
      local icon = num_icons[i] or tostring(i)

      local actions = {
        click = function() require("exec.utils").switch_tab(i) end,
      }

      table.insert(line, { icon .. "  ", hl, actions })
    end
  end

  return line
end

---Renders navigation indicator (right side)
---@param active string "term" or "commands"
M.nav = function(active)
  local term_hl = (active == "term") and "ExecTabActive" or "ExecTabInactive"
  local cmd_hl = (active == "commands") and "ExecTabActive" or "ExecTabInactive"

  return {
    {
      " Terminal ",
      term_hl,
      { click = function() require("exec").open() end },
    },
    { " " },
    {
      " Commands",
      cmd_hl,
      { click = function() require("exec.api").edit_cmds() end },
    },
  }
end

---Renders current cursor position (line : col)
M.cursor_pos = function()
  local view = state.current_view
  if view == "help" then
    view = state.help_return_view -- Fallback to the underlying view for cursor
  end

  local win = (view == "term") and state.term_win or state.edit_win
  if not win or not vim.api.nvim_win_is_valid(win) then
    return { { "󰉢 0 : 0 ", "ExecLabel" } }
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    { string.format("󰉢 %d : %d ", cursor[1], cursor[2]), "ExecLabel" },
  }
end

return M
