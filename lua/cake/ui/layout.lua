local state = require "cake.state"
local voltui = require "volt.ui"
local components = require "cake.ui.components"

local M = {}

local function pad_vertical(lines, pos)
  local ypad = state.ypad or 0
  if ypad <= 0 then return lines end

  local res = {}

  if pos == "top" then
    for _ = 1, ypad do
      table.insert(res, { { " " } })
    end
  end

  vim.list_extend(res, lines)

  if pos == "bottom" then
    for _ = 1, ypad do
      table.insert(res, { { " " } })
    end
  end

  return res
end

M.header = {
  {
    lines = function()
      local tabs = components.tabs()
      local nav = components.nav(state.current_view)
      local title = { state.config.title, "CakeTitle" }

      local W = state.w - (state.xpad * 2)
      local w_tabs = voltui.line_w(tabs)
      local w_nav = voltui.line_w(nav)
      local w_title = vim.api.nvim_strwidth(title[1])

      local center_start = math.floor((W - w_title) / 2)
      local pad1 = center_start - w_tabs
      if pad1 < 1 then pad1 = 1 end

      local line = {}
      vim.list_extend(line, tabs)
      table.insert(line, { string.rep(" ", pad1) })
      table.insert(line, title)

      local current_w = w_tabs + pad1 + w_title
      local pad2 = W - current_w - w_nav
      if pad2 < 1 then pad2 = 1 end

      table.insert(line, { string.rep(" ", pad2) })
      vim.list_extend(line, nav)

      return pad_vertical({ line }, "top")
    end,
    name = "header",
  },
}

M.footer = {
  {
    lines = function()
      local m = state.config.mappings
      local line = {}
      local view = state.current_view

      if view == "term" then
        vim.list_extend(line, {
          { " " .. m.edit_commands .. " ", "CakeKey" },
          { "  Edit Cmd ", "CakeLabel" },
          { " " },
          { " " .. m.rerun .. " ", "CakeKey" },
          { "  Rerun ", "CakeLabel" },
          { " " },
          { " " .. m.new_tab .. " ", "CakeKey" },
          { " 󰓩 New Tab ", "CakeLabel" },
          { " " },
          { " ? ", "CakeKey" },
          { "  Help ", "CakeLabel" },
        })
      elseif view == "commands" then
        vim.list_extend(line, {
          { " " .. m.edit_commands .. " ", "CakeKey" },
          { "  Terminal ", "CakeLabel" },
          { " " },
          { " " .. m.edit_cwd .. " ", "CakeKey" },
          { "  Edit CWD ", "CakeLabel" },
        })
      elseif view == "cwd" then
        vim.list_extend(line, {
          { " " .. m.edit_cwd .. " ", "CakeKey" },
          { "  Back ", "CakeLabel" },
        })
      elseif view == "help" then
        vim.list_extend(line, {
          { " q ", "CakeKey" },
          { " 󰈆 Quit ", "CakeLabel" },
        })
      end

      table.insert(line, { "_pad_" })
      vim.list_extend(line, components.cursor_pos())

      return pad_vertical(
        { voltui.hpad(line, state.w - (state.xpad * 2)) },
        "bottom"
      )
    end,
    name = "footer",
  },
}

return M
