local state = require "cake.state"
local voltui = require "volt.ui"
local components = require "cake.components"

local M = {}

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
      for _, v in ipairs(tabs) do
        table.insert(line, v)
      end
      table.insert(line, { string.rep(" ", pad1) })
      table.insert(line, title)

      local current_w = w_tabs + pad1 + w_title
      local pad2 = W - current_w - w_nav
      if pad2 < 1 then pad2 = 1 end

      table.insert(line, { string.rep(" ", pad2) })
      for _, v in ipairs(nav) do
        table.insert(line, v)
      end

      return { line }
    end,
    name = "header",
  },
}

M.footer = {
  {
    lines = function()
      local m = state.config.mappings
      local line = {
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
      }

      table.insert(line, { "_pad_" })

      local right = components.cursor_pos()

      for _, v in ipairs(right) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "footer",
  },
}

M.edit_footer = {
  {
    lines = function()
      local m = state.config.mappings
      local line = {
        { " " .. m.edit_commands .. " ", "CakeKey" },
        { "  Terminal ", "CakeLabel" },
        { " " },
        { " " .. m.edit_cwd .. " ", "CakeKey" },
        { "  Edit CWD ", "CakeLabel" },
      }

      table.insert(line, { "_pad_" })

      local right = components.cursor_pos()

      for _, v in ipairs(right) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "edit_footer",
  },
}

M.cwd_footer = {
  {
    lines = function()
      local m = state.config.mappings
      local line = {
        { " " .. m.edit_cwd .. " ", "CakeKey" },
        { "  Back ", "CakeLabel" },
      }

      table.insert(line, { "_pad_" })

      local right = components.cursor_pos()

      for _, v in ipairs(right) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "cwd_footer",
  },
}

M.help_footer = {
  {
    lines = function()
      local line = {
        { " q ", "CakeKey" },
        { " 󰈆 Quit ", "CakeLabel" },
      }

      table.insert(line, { "_pad_" })

      local right = components.cursor_pos()

      for _, v in ipairs(right) do
        table.insert(line, v)
      end

      return { voltui.hpad(line, state.w - (state.xpad * 2)) }
    end,
    name = "help_footer",
  },
}

return M
