local state = require "bday.state"

local M = {}

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
    -- placeholder
    local icon = num_icons[1] or "1"
    table.insert(line, { icon .. " ", "BdayTabActive" })
  else
    for i, _ in ipairs(state.tabs) do
      local is_active = (i == state.active_tab)
      local hl = is_active and "BdayTabActive" or "BdayTabInactive"
      local icon = num_icons[i] or tostring(i)

      local actions = {
        click = function() require("bday.api").switch_tab(i) end,
      }

      table.insert(line, { icon .. "  ", hl, actions })
    end
  end

  return line
end

---@param active string "term" or "cmd"
M.nav = function(active)
  local term_hl = (active == "term") and "BdayTabActive" or "BdayTabInactive"
  local cmd_hl = (active == "commands") and "BdayTabActive" or "BdayTabInactive"

  return {
    {
      " Terminal ",
      term_hl,
      { click = function() require("bday").open() end },
    },
    { " " },
    {
      " Commands",
      cmd_hl,
      { click = function() require("bday.api").edit_cmds() end },
    },
  }
end

M.cursor_pos = function()
  local view = state.current_view
  if view == "help" then view = state.help.return_view end

  local win = (view == "term") and state.term.win or state.edit.win
  if not win or not vim.api.nvim_win_is_valid(win) then
    return { { "󰉢 0 : 0 ", "BdayLabel" } }
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    { string.format("󰉢 %d : %d ", cursor[1], cursor[2]), "BdayLabel" },
  }
end

return M
