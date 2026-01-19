local volt = require "volt"
local voltui = require "volt.ui"
local state = require "bday.state"
local utils = require "bday.utils"

local M = {}

M.open = function()
  state.current_view = "commands"
  vim.cmd "stopinsert"

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    volt.close(state.volt_buf)
  end

  -- header
  local layout = require "bday.layout"
  state.edit.volt_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.edit.volt_buf,
      layout = layout.edit_header,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local header_h = require("volt.state")[state.edit.volt_buf].h

  -- dynamic sizing (same as main UI)
  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))
  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))

  local border_h = 2
  local total_borders = border_h * 3

  state.term.h = target_total_h - header_h - state.footer.h - total_borders
  if state.term.h < 1 then state.term.h = 1 end

  local total_h = header_h + state.term.h + state.footer.h + total_borders
  local start_row = math.floor((vim.o.lines - total_h) / 2)

  local header_opts = {
    relative = "editor",
    width = state.w,
    height = header_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row,
    style = "minimal",
    border = "single",
  }
  state.edit.volt_win =
    vim.api.nvim_open_win(state.edit.volt_buf, false, header_opts)
  vim.api.nvim_win_set_hl_ns(state.edit.volt_win, state.ns)

  -- create/reuse the text buffer
  if not state.edit.buf or not vim.api.nvim_buf_is_valid(state.edit.buf) then
    state.edit.buf = vim.api.nvim_create_buf(false, true)

    pcall(vim.api.nvim_buf_set_name, state.edit.buf, "Commands")
    vim.api.nvim_set_option_value(
      "buftype",
      "acwrite",
      { buf = state.edit.buf }
    )
  end

  -- load current tab's commands
  local tab = state.tabs[state.active_tab]
  local cmds = (tab and tab.commands) or {}
  vim.api.nvim_buf_set_lines(state.edit.buf, 0, -1, false, cmds)
  vim.api.nvim_set_option_value("modified", false, { buf = state.edit.buf })

  vim.api.nvim_set_option_value("modified", false, { buf = state.edit.buf })

  local container_border = state.config.border and "single"
    or { " ", " ", " ", " ", " ", " ", " ", " " }
  state.edit.container_buf = vim.api.nvim_create_buf(false, true)

  local container_opts = {
    relative = "editor",
    width = state.w,
    height = state.term.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h,
    style = "minimal",
    border = container_border,
  }

  state.edit.container_win =
    vim.api.nvim_open_win(state.edit.container_buf, false, container_opts)
  vim.api.nvim_win_set_hl_ns(state.edit.container_win, state.term_ns)

  local term_w = state.w - (state.xpad * 2)
  local term_col = container_opts.col + state.xpad + 1

  local editor_opts = {
    relative = "editor",
    width = term_w,
    height = state.term.h,
    col = term_col,
    row = container_opts.row + 1,
    style = "minimal",
    border = "none",
  }
  state.edit.win = vim.api.nvim_open_win(state.edit.buf, true, editor_opts)
  -- term namespace for background consistency
  vim.api.nvim_win_set_hl_ns(state.edit.win, state.term_ns)

  state.edit.footer_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.edit.footer_buf,
      layout = layout.edit_footer,
      xpad = state.xpad,
      ns = state.term_ns,
    },
  }

  local footer_opts = {
    relative = "editor",
    width = state.w,
    height = state.footer.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h + state.term.h + border_h,
    style = "minimal",
    border = "single",
  }
  state.edit.footer_win =
    vim.api.nvim_open_win(state.edit.footer_buf, false, footer_opts)
  vim.api.nvim_win_set_hl_ns(state.edit.footer_win, state.term_ns)

  require("volt.events").add { state.edit.volt_buf, state.edit.footer_buf }

  vim.schedule(function()
    if state.edit.win and vim.api.nvim_win_is_valid(state.edit.win) then
      vim.api.nvim_set_current_win(state.edit.win)
    end
  end)

  volt.run(state.edit.volt_buf, { h = header_h, w = state.w })
  volt.run(state.edit.footer_buf, { h = state.footer.h, w = state.w })

  require("bday.api").setup_cursor_events(state.edit.buf)

  -- cleanup
  local function close_all()
    local function sc(w)
      if w and vim.api.nvim_win_is_valid(w) then
        vim.api.nvim_win_close(w, true)
      end
    end
    sc(state.edit.volt_win)
    sc(state.edit.win)
    sc(state.edit.container_win)
    sc(state.edit.footer_win)
    state.edit.volt_win = nil
    state.edit.win = nil
    state.edit.container_win = nil
    state.edit.container_buf = nil
    state.edit.footer_win = nil
    state.edit.volt_buf = nil
    -- state.edit.buf = nil
    state.edit.footer_buf = nil

    if state.footer.cursor_timer then
      state.footer.cursor_timer:stop()
      state.footer.cursor_timer = nil
    end
  end

  local mappings_config = {
    bufs = { state.edit.volt_buf, state.edit.footer_buf },
    winclosed_event = true,
    after_close = close_all,
  }

  volt.mappings(mappings_config)

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.edit.win),
    once = true,
    callback = function()
      if state.resetting then return end

      pcall(function()
        vim.schedule(
          function() require("volt.utils").close(mappings_config) end
        )
      end)
    end,
  })

  local close_ui = function() require("volt.utils").close(mappings_config) end

  vim.keymap.set(
    "n",
    "?",
    function() require("bday.help").open() end,
    { buffer = state.edit.buf, silent = true, nowait = true }
  )

  vim.keymap.set(
    "n",
    "<Esc>",
    function() require("bday").open() end,
    { buffer = state.edit.buf, silent = true, nowait = true }
  )

  vim.keymap.set(
    "n",
    state.config.edit_key,
    function() require("bday").open() end,
    { buffer = state.edit.buf, silent = true }
  )

  local group = vim.api.nvim_create_augroup("BdayEditSave", { clear = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.edit.buf,
    group = group,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(state.edit.buf, 0, -1, false)
      local current_tab = state.tabs[state.active_tab]
      if current_tab then
        current_tab.commands = {}
        for _, line in ipairs(lines) do
          if line ~= "" then table.insert(current_tab.commands, line) end
        end
        require("bday.utils").save_tabs()
        vim.api.nvim_set_option_value(
          "modified",
          false,
          { buf = state.edit.buf }
        )
        vim.notify("Commands saved!", vim.log.levels.INFO)
      end
    end,
  })

  state.resetting = false
end

return M
