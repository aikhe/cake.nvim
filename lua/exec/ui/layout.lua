local state = require "exec.state"
local voltui = require "volt.ui"
local components = require "exec.ui.components"

local M = {}

M.header = {
  {
    lines = function()
      local tabs = components.tabs()
      local nav = components.nav "term"
      local title = { " 󰆍 exec.nvim ", "ExecTitle" }

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
      local line = {
        { " " .. state.config.edit_key .. " ", "ExecKey" },
        { "  Edit Cmd ", "ExecLabel" },
        { " " },
        { " n ", "ExecKey" },
        { " 󰓩 New Tab ", "ExecLabel" },
        { " " },
        { " ? ", "ExecKey" },
        { "  Help ", "ExecLabel" },
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

M.edit_header = {
  {
    lines = function()
      local title = { " 󰆍 exec.nvim ", "ExecTitle" }
      local tabs = components.tabs()
      local nav = components.nav "commands"

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
    name = "edit_header",
  },
}

M.edit_footer = {
  {
    lines = function()
      local line = {
        { " " .. state.config.edit_key .. " ", "ExecKey" },
        { "  Terminal ", "ExecLabel" },
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

M.help_footer = {
  {
    lines = function()
      local line = {
        { " q ", "ExecKey" },
        { " 󰈆 Quit ", "ExecLabel" },
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
