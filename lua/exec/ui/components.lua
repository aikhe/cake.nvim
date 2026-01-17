local state = require "exec.state"

local M = {}

-- Renders tab numbers in header (simple text like nav)
M.tabs = function()
  local line = {}

  if #state.tabs == 0 then
    -- No tabs yet, show placeholder
    table.insert(line, { " 1 ", "ExecTabActive" })
  else
    for i, _ in ipairs(state.tabs) do
      local is_active = (i == state.active_tab)
      local hl = is_active and "ExecTabActive" or "ExecTabInactive"

      local actions = {
        click = function()
          require("exec.utils").switch_tab(i)
        end,
      }

      table.insert(line, { " " .. i .. " ", hl, actions })
    end
  end

  return line
end

-- Renders navigation indicator (right side)
-- @param active string "term" or "commands"
M.nav = function(active)
  local term_hl = (active == "term") and "ExecTabActive" or "ExecTabInactive"
  local cmd_hl = (active == "commands") and "ExecTabActive" or "ExecTabInactive"

  return {
    { " Terminal ", term_hl },
    { " Commands ", cmd_hl },
  }
end

return M
