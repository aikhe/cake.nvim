local M = {}

local volt = require "volt"
local layout = require "cake.ui.layout"
local state = require "cake.state"

function M.open()
  if state.current_view == "help" then return end

  state.help.return_view = state.current_view

  local target_win = (state.current_view == "term") and state.term.win
    or state.edit.win
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then return end

  state.help.prev_buf = vim.api.nvim_win_get_buf(target_win)

  state.current_view = "help"

  if not state.help.buf or not vim.api.nvim_buf_is_valid(state.help.buf) then
    state.help.buf = vim.api.nvim_create_buf(false, true)

    local m = state.config.mappings
    local help_text = {
      "",
      "Keybindings",
      "-----------",
      "",
      string.format("%-6s Edit Commands", m.edit_commands),
      string.format("%-6s New Tab", m.new_tab),
      string.format("%-6s Kill Tab", m.kill_tab),
      string.format("%-6s Rerun Commands", m.rerun),
      string.format("%-6s Next Tab", m.next_tab),
      string.format("%-6s Prev Tab", m.prev_tab),
      string.format("%-6s Switch Tab", "1-9"),
      string.format("%-6s Help", "?"),
      "q      Quit in Help",
      "",
      ":w     Save Tab/Commands",
      "",
    }

    vim.api.nvim_buf_set_lines(state.help.buf, 0, -1, false, help_text)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.help.buf })
    vim.api.nvim_set_option_value(
      "filetype",
      "cake_help",
      { buf = state.help.buf }
    )
  end

  vim.api.nvim_win_set_buf(target_win, state.help.buf)

  -- disable line numbers in split mode
  if state.is_split then
    vim.api.nvim_set_option_value("number", false, { win = target_win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = target_win })
  end

  local footer_buf = (state.help.return_view == "term") and state.footer.buf
    or state.edit.footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.footer,
        xpad = state.xpad,
        ns = state.term_ns,
      },
    }

    volt.redraw(footer_buf, "footer")
  end

  require "cake.mappings"(state.help.buf, "help")
end

function M.close()
  if state.current_view ~= "help" then return end

  local target_win = (state.help.return_view == "term") and state.term.win
    or state.edit.win

  if
    target_win
    and vim.api.nvim_win_is_valid(target_win)
    and state.help.prev_buf
    and vim.api.nvim_buf_is_valid(state.help.prev_buf)
  then
    vim.api.nvim_win_set_buf(target_win, state.help.prev_buf)
  end

  local footer_buf = (state.help.return_view == "term") and state.footer.buf
    or state.edit.footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.footer,
        xpad = state.xpad,
        ns = state.term_ns,
      },
    }

    volt.redraw(footer_buf, "footer")
  end

  state.current_view = state.help.return_view
  state.help.return_view = nil
  state.help.prev_buf = nil
end

return M
