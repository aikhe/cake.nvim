local state = require "cake.state"

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
    "󰎹",
  }

  if #state.tabs == 0 then
    -- placeholder
    local icon = num_icons[1] or "1"
    table.insert(line, { icon .. " ", "CakeTabActive" })
  else
    for i, _ in ipairs(state.tabs) do
      local is_active = (i == state.active_tab)
      local hl = is_active and "CakeTabActive" or "CakeTabInactive"
      local icon = num_icons[i] or tostring(i)

      local actions = {
        click = function() require("cake.core.tabs").switch(i) end,
        hover = { id = "tab_" .. i, redraw = "header" },
      }

      if vim.g.nvmark_hovered == "tab_" .. i and not is_active then
        hl = "CakeNavHover"
      end

      table.insert(line, { icon .. "  ", hl, actions })
    end
  end

  return line
end

---@param active string "term" or "cmd"
M.nav = function(active)
  local term_hl = (active == "term") and "CakeTabActive" or "CakeTabInactive"
  local cmd_hl = (active == "commands") and "CakeTabActive" or "CakeTabInactive"

  if vim.g.nvmark_hovered == "nav_term" and active ~= "term" then
    term_hl = "CakeNavHover"
  end
  if vim.g.nvmark_hovered == "nav_cmd" and active ~= "commands" then
    cmd_hl = "CakeNavHover"
  end

  return {
    {
      " Terminal ",
      term_hl,
      {
        click = function() require("cake").open() end,
        hover = { id = "nav_term", redraw = "header" },
      },
    },
    { " " },
    {
      " Commands",
      cmd_hl,
      {
        click = function()
          state.resetting = true
          require("cake.ui.edit").open()
        end,
        hover = { id = "nav_cmd", redraw = "header" },
      },
    },
  }
end

M.cursor_pos = function()
  local view = state.current_view
  if view == "help" then view = state.help.return_view end

  local win = (view == "term") and state.term.win or state.edit.win
  if not win or not vim.api.nvim_win_is_valid(win) then
    return { { "󰉢 0 : 0 ", "CakeLabel" } }
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  return {
    { string.format("󰉢 %d : %d ", cursor[1], cursor[2]), "CakeLabel" },
  }
end

return M
