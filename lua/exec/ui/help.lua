local M = {}

local volt = require "volt"
local layout = require "exec.ui.layout"
local state = require "exec.state"

M.open = function()
  if state.current_view == "help" then return end

  state.help.return_view = state.current_view

  local target_win = (state.current_view == "term") and state.term.win
    or state.edit.win
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then return end

  state.help.prev_buf = vim.api.nvim_win_get_buf(target_win)

  state.current_view = "help"

  if not state.help.buf or not vim.api.nvim_buf_is_valid(state.help.buf) then
    state.help.buf = vim.api.nvim_create_buf(false, true)

    local help_text = {
      "",
      "Keybindings",
      "-----------",
      "",
      string.format("%-6s Edit Commands", state.config.edit_key),
      "n      New Tab",
      "x      Kill Tab",
      "r      Rerun Commands",
      ":w     Save Tab/Commands",
      "1-9    Switch Tab",
      "?      Help",
      "q      Quit",
      "",
    }

    vim.api.nvim_buf_set_lines(state.help.buf, 0, -1, false, help_text)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.help.buf })
    vim.api.nvim_set_option_value(
      "filetype",
      "exec_help",
      { buf = state.help.buf }
    )
  end

  vim.api.nvim_win_set_buf(target_win, state.help.buf)

  local footer_buf = (state.help.return_view == "term") and state.footer.buf
    or state.edit.footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.help_footer,
        xpad = state.xpad,
        ns = state.ns,
      },
    }

    volt.redraw(footer_buf, "help_footer")
  end

  local opts = { buffer = state.help.buf, noremap = true, silent = true }

  local close_help = function() M.close() end

  vim.keymap.set("n", "q", close_help, opts)
  vim.keymap.set("n", "<Esc>", close_help, opts)
end

M.close = function()
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
  local footer_layout = (state.help.return_view == "term") and layout.footer
    or layout.edit_footer
  local footer_key = (state.help.return_view == "term") and "footer"
    or "edit_footer"

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = footer_layout,
        xpad = state.xpad,
        ns = state.ns,
      },
    }

    volt.redraw(footer_buf, footer_key)
  end

  state.current_view = state.help.return_view
  state.help.return_view = nil
  state.help.prev_buf = nil
end

return M
