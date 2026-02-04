local volt = require "volt"
local state = require "cake.state"
local layout = require "cake.ui.layout"

local M = {}

local function cleanup_view_state(view_s)
  local function sc(w)
    if w and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_close(w, true)
    end
  end
  sc(view_s.header_win)
  sc(view_s.win)
  sc(view_s.container_win)
  sc(view_s.footer_win)

  view_s.header_win = nil
  view_s.win = nil
  view_s.container_win = nil
  view_s.container_buf = nil
  view_s.footer_win = nil
  view_s.header_buf = nil
  view_s.footer_buf = nil
end

local function setup_view(opts)
  local view_s = opts.view_state

  -- setup volt buffers
  view_s.header_buf = vim.api.nvim_create_buf(false, true)
  view_s.footer_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = view_s.header_buf,
      layout = opts.header,
      xpad = state.xpad,
      ns = state.ns,
    },
    {
      buf = view_s.footer_buf,
      layout = opts.footer,
      xpad = state.xpad,
      ns = state.term_ns,
    },
  }

  local header_h = require("volt.state")[view_s.header_buf].h

  -- sizing
  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))
  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))
  local border_h = 2
  local total_borders = border_h * 3
  state.term.h = target_total_h - header_h - state.footer.h - total_borders
  if state.term.h < 1 then state.term.h = 1 end

  local total_h = header_h + state.term.h + state.footer.h + total_borders
  local start_row = math.floor((vim.o.lines - total_h) / 2)

  -- header win
  view_s.header_win = vim.api.nvim_open_win(view_s.header_buf, false, {
    relative = "editor",
    width = state.w,
    height = header_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row,
    style = "minimal",
    border = "single",
  })
  vim.api.nvim_win_set_hl_ns(view_s.header_win, state.ns)

  -- text buffer creation/reuse
  if not view_s.buf or not vim.api.nvim_buf_is_valid(view_s.buf) then
    view_s.buf = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, view_s.buf, opts.buf_name)
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = view_s.buf })
  end

  -- populate buffer
  opts.on_setup(view_s.buf)
  vim.api.nvim_set_option_value("modified", false, { buf = view_s.buf })

  -- container win
  local container_border = state.config.border and "single"
    or { " ", " ", " ", " ", " ", " ", " ", " " }
  view_s.container_buf = vim.api.nvim_create_buf(false, true)
  view_s.container_win = vim.api.nvim_open_win(view_s.container_buf, false, {
    relative = "editor",
    width = state.w,
    height = state.term.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h,
    style = "minimal",
    border = container_border,
  })
  vim.api.nvim_win_set_hl_ns(view_s.container_win, state.term_ns)

  -- editor win
  local term_w = state.w - (state.xpad * 2)
  local term_col = (vim.o.columns - state.w) / 2 + state.xpad + 1
  view_s.win = vim.api.nvim_open_win(view_s.buf, true, {
    relative = "editor",
    width = term_w,
    height = state.term.h,
    col = term_col,
    row = start_row + header_h + border_h + 1,
    style = "minimal",
    border = "none",
  })
  vim.api.nvim_win_set_hl_ns(view_s.win, state.term_ns)

  -- disable line numbers
  vim.api.nvim_set_option_value("number", false, { win = view_s.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = view_s.win })

  -- footer win
  view_s.footer_win = vim.api.nvim_open_win(view_s.footer_buf, false, {
    relative = "editor",
    width = state.w,
    height = state.footer.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h + state.term.h + border_h,
    style = "minimal",
    border = "single",
  })
  vim.api.nvim_win_set_hl_ns(view_s.footer_win, state.term_ns)

  -- volt events
  require("volt.events").add { view_s.header_buf, view_s.footer_buf }

  vim.schedule(function()
    if view_s.win and vim.api.nvim_win_is_valid(view_s.win) then
      vim.api.nvim_set_current_win(view_s.win)
    end
  end)

  volt.run(view_s.header_buf, { h = header_h, w = state.w })
  volt.run(view_s.footer_buf, { h = state.footer.h, w = state.w })

  require("cake.core.terminal").setup_cursor_events(view_s.buf)

  -- cleanup
  local function close_all()
    cleanup_view_state(view_s)
    if state.footer.cursor_timer then
      state.footer.cursor_timer:stop()
      state.footer.cursor_timer = nil
    end
  end

  local mappings_config = {
    bufs = { view_s.header_buf, view_s.footer_buf },
    winclosed_event = true,
    after_close = close_all,
  }
  volt.mappings(mappings_config)

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(view_s.win),
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

  -- keymaps
  require "cake.mappings"(view_s.buf, opts.view_type)

  -- save logic
  if opts.on_save then
    local group = vim.api.nvim_create_augroup(
      "CakeEditSave_" .. opts.buf_name,
      { clear = true }
    )
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = view_s.buf,
      group = group,
      callback = function()
        opts.on_save(view_s.buf)
        vim.api.nvim_set_option_value("modified", false, { buf = view_s.buf })
      end,
    })
  end
  state.resetting = false
end

function M.open()
  state.current_view = "commands"
  vim.cmd "stopinsert"

  -- split mode: swap buffer in split window
  if state.is_split then
    M.open_split_edit()
    return
  end

  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    volt.close(state.header.buf)
  end
  if
    state.cwd_edit.header_buf
    and vim.api.nvim_buf_is_valid(state.cwd_edit.header_buf)
  then
    volt.close(state.cwd_edit.header_buf)
  end

  setup_view {
    view_state = state.edit,
    view_type = "commands",
    header = layout.header,
    footer = layout.footer,
    buf_name = "Commands",
    on_setup = function(buf)
      local tab = state.tabs[state.active_tab]
      local cmds = (tab and tab.commands) or {}
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, cmds)
    end,
    on_save = function(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end
      local current_tab = state.tabs[state.active_tab]
      if current_tab then
        current_tab.commands = lines
        require("cake.core.session").save_tabs()
        vim.notify("Commands saved!", vim.log.levels.INFO)
      end
    end,
  }
end

function M.open_cwd()
  state.current_view = "cwd"
  vim.cmd "stopinsert"

  -- split mode: swap buffer in split window
  if state.is_split then
    M.open_split_cwd()
    return
  end

  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    volt.close(state.header.buf)
  end
  if
    state.edit.header_buf and vim.api.nvim_buf_is_valid(state.edit.header_buf)
  then
    volt.close(state.edit.header_buf)
  end

  setup_view {
    view_state = state.cwd_edit,
    view_type = "cwd",
    header = layout.header,
    footer = layout.footer,
    buf_name = "CWD",
    on_setup = function(buf)
      local tab = state.tabs[state.active_tab]
      local cwd = (tab and tab.cwd) or ""
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { cwd })
    end,
    on_save = function(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local new_cwd = lines[1] or ""
      local current_tab = state.tabs[state.active_tab]
      if current_tab then
        current_tab.cwd = new_cwd
        require("cake.core.session").save_tabs()
        vim.notify("CWD saved!", vim.log.levels.INFO)
      end
    end,
  }
end

-- split mode: swap buffer in split window for editing cwd
function M.open_split_cwd()
  if not state.term.win or not vim.api.nvim_win_is_valid(state.term.win) then
    return
  end

  state.edit.prev_term_buf = state.term.buf

  if not state.cwd_edit.buf or not vim.api.nvim_buf_is_valid(state.cwd_edit.buf) then
    state.cwd_edit.buf = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, state.cwd_edit.buf, "CWD")
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.cwd_edit.buf })

    -- save autocmd
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = state.cwd_edit.buf,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(state.cwd_edit.buf, 0, -1, false)
        local new_cwd = lines[1] or ""
        local current_tab = state.tabs[state.active_tab]
        if current_tab then
          current_tab.cwd = new_cwd
          require("cake.core.session").save_tabs()
          vim.notify("CWD saved!", vim.log.levels.INFO)
        end
        vim.api.nvim_set_option_value("modified", false, { buf = state.cwd_edit.buf })
      end,
    })
  end

  local tab = state.tabs[state.active_tab]
  local cwd = (tab and tab.cwd) or ""
  vim.api.nvim_buf_set_lines(state.cwd_edit.buf, 0, -1, false, { cwd })
  vim.api.nvim_set_option_value("modified", false, { buf = state.cwd_edit.buf })

  vim.api.nvim_win_set_buf(state.term.win, state.cwd_edit.buf)

  vim.api.nvim_set_option_value("number", false, { win = state.term.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = state.term.win })

  require "cake.mappings"(state.cwd_edit.buf, "cwd")
end

-- split mode: swap buffer in split window for editing commands
function M.open_split_edit()
  if not state.term.win or not vim.api.nvim_win_is_valid(state.term.win) then
    return
  end

  -- store current terminal buffer to restore later
  state.edit.prev_term_buf = state.term.buf

  -- create or reuse edit buffer
  if not state.edit.buf or not vim.api.nvim_buf_is_valid(state.edit.buf) then
    state.edit.buf = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, state.edit.buf, "Commands")
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.edit.buf })

    -- save autocmd
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = state.edit.buf,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(state.edit.buf, 0, -1, false)
        while #lines > 0 and lines[#lines] == "" do
          table.remove(lines)
        end
        local current_tab = state.tabs[state.active_tab]
        if current_tab then
          current_tab.commands = lines
          require("cake.core.session").save_tabs()
          vim.notify("Commands saved!", vim.log.levels.INFO)
        end
        vim.api.nvim_set_option_value("modified", false, { buf = state.edit.buf })
      end,
    })
  end

  -- populate with current commands
  local tab = state.tabs[state.active_tab]
  local cmds = (tab and tab.commands) or {}
  vim.api.nvim_buf_set_lines(state.edit.buf, 0, -1, false, cmds)
  vim.api.nvim_set_option_value("modified", false, { buf = state.edit.buf })

  -- swap buffer
  vim.api.nvim_win_set_buf(state.term.win, state.edit.buf)

  -- disable line numbers
  vim.api.nvim_set_option_value("number", false, { win = state.term.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = state.term.win })

  -- setup mappings
  require "cake.mappings"(state.edit.buf, "commands")
end

-- split mode: return to terminal from edit
function M.back_to_split_term()
  if not state.term.win or not vim.api.nvim_win_is_valid(state.term.win) then
    return
  end

  state.current_view = "term"

  if state.edit.prev_term_buf and vim.api.nvim_buf_is_valid(state.edit.prev_term_buf) then
    vim.api.nvim_win_set_buf(state.term.win, state.edit.prev_term_buf)
    require "cake.mappings"(state.edit.prev_term_buf, "term")
  end
end

return M
