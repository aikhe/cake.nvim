local state = require "exec.state"
local voltui = require "volt.ui"
local components = require "exec.ui.components"

local M = {}

-- Header for terminal view: tabs left, nav right (styled like footer)
M.main_layout = {
  {
    lines = function()
      local tabs = components.tabs()
      local nav = components.nav "term"

      -- Build line with tabs on left, pad, nav on right
      local line = {}
      for _, v in ipairs(tabs) do
        table.insert(line, v)
      end
      table.insert(line, { "_pad_" })
      for _, v in ipairs(nav) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "header",
  },
}

-- Footer with keybinds
M.footer_layout = {
  {
    lines = function()
      return {
        {
          { " :q ", "ExecKey" },
          { " Quit ", "ExecLabel" },
          { "  " },
          { " p ", "ExecKey" },
          { " Edit ", "ExecLabel" },
          { "  " },
          { " n ", "ExecKey" },
          { " New ", "ExecLabel" },
          { "  " },
          { " s ", "ExecKey" },
          { " Save ", "ExecLabel" },
          { "  " },
          { " x ", "ExecKey" },
          { " Kill ", "ExecLabel" },
        },
      }
    end,
    name = "footer",
  },
}

-- Header for edit/commands view: tabs left, nav right (commands active)
M.edit_header_layout = {
  {
    lines = function()
      local tabs = components.tabs()
      local nav = components.nav "commands"

      local line = {}
      for _, v in ipairs(tabs) do
        table.insert(line, v)
      end
      table.insert(line, { "_pad_" })
      for _, v in ipairs(nav) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "edit_header",
  },
}

-- Footer for edit view
M.edit_footer_layout = {
  {
    lines = function()
      return {
        {
          { " :q ", "ExecKey" },
          { " Quit ", "ExecLabel" },
          { "  " },
          { " p ", "ExecKey" },
          { " Terminal ", "ExecLabel" },
          { "  " },
          { " Ctrl+s ", "ExecKey" },
          { " Save ", "ExecLabel" },
        },
      }
    end,
    name = "edit_footer",
  },
}

return M
