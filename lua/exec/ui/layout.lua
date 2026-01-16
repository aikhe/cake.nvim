local state = require "exec.state"
local voltui = require "volt.ui"

local M = {}

M.title = function()
  local width = state.w - (state.xpad * 2) - 4
  local term_hl = state.current_tab == "term" and "ExecTabActive"
    or "ExecTabInactive"
  local cmds_hl = state.current_tab == "commands" and "ExecTabActive"
    or "ExecTabInactive"

  local line = {
    { "  ", "ExecAccent" },
    { "Exec  ", "ExecTitle" },
    {
      " Term ",
      term_hl,
      {
        click = function()
          -- Already on term tab
        end,
      },
    },
    { "  ", "" },
    {
      " Commands ",
      cmds_hl,
      {
        click = function()
          vim.cmd "stopinsert"
          vim.schedule(function()
            state.resetting = true
            state.current_tab = "commands"
            require("exec.api").edit_cmds()
          end)
        end,
      },
    },
  }

  local lines = { voltui.hpad(line, width) }
  voltui.border(lines)
  return lines
end

M.separator = function()
  return {
    {
      { string.rep("─", state.w - (state.xpad * 2)), "ExecLabel" },
    },
  }
end

M.footer = function()
  local width = state.w - (state.xpad * 2)
  local key = function(char) return { " " .. char .. " ", "ExecKey" } end
  local txt = function(str) return { str, "ExecLabel" } end

  local line = {
    key "ESC",
    txt " Close  ",
    key "r",
    txt " Reset  ",
    key "t",
    txt " New  ",
    { "_pad_", "" },
    key "p",
    txt " Edit  ",
  }

  return { voltui.hpad(line, width) }
end

M.edit_header = function()
  local width = state.w - (state.xpad * 2) - 4
  local term_hl = state.current_tab == "term" and "ExecTabActive"
    or "ExecTabInactive"
  local cmds_hl = state.current_tab == "commands" and "ExecTabActive"
    or "ExecTabInactive"

  local line = {
    { "  ", "ExecAccent" },
    { "Exec  ", "ExecTitle" },
    {
      " Term ",
      term_hl,
      {
        click = function()
          vim.schedule(function()
            state.resetting = true
            state.current_tab = "term"
            require("exec").open()
          end)
        end,
      },
    },
    { "  ", "" },
    {
      " Commands ",
      cmds_hl,
      {
        click = function()
          -- Already on commands tab
        end,
      },
    },
  }

  local lines = { voltui.hpad(line, width) }
  voltui.border(lines)
  return lines
end

M.edit_footer = function()
  local width = state.w - (state.xpad * 2)
  local key = function(char) return { " " .. char .. " ", "ExecKey" } end
  local txt = function(str) return { str, "ExecLabel" } end

  local line = {
    key "ESC",
    txt " Cancel  ",
    { "_pad_", "" },
    key "Ctrl+S",
    txt " Save Commands ",
  }

  return { voltui.hpad(line, width) }
end

M.main_layout = {
  {
    lines = M.title,
    name = "title",
  },
}

M.footer_layout = {
  {
    lines = M.footer,
    name = "footer",
  },
}

M.edit_header_layout = {
  {
    lines = M.edit_header,
    name = "header",
  },
}

M.edit_footer_layout = {
  {
    lines = M.edit_footer,
    name = "footer",
  },
}

return M
