local volt = require "volt"
local state = require "cake.state"
local layout = require "cake.layout"

local M = {}

local function cleanup_view_state(view_s)
  local function sc(w)
    if w and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_close(w, true)
    end
  end
  sc(view_s.volt_win)
  sc(view_s.win)
  sc(view_s.container_win)
  sc(view_s.footer_win)

  view_s.volt_win = nil
  view_s.win = nil
  view_s.container_win = nil
  view_s.container_buf = nil
  view_s.footer_win = nil
  view_s.volt_buf = nil
  view_s.footer_buf = nil
end

local function setup_view(opts)
  local view_s = opts.view_state

  -- setup volt buffers
  view_s.volt_buf = vim.api.nvim_create_buf(false, true)
  view_s.footer_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = view_s.volt_buf,
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

  local header_h = require("volt.state")[view_s.volt_buf].h

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
  local header_opts = {
    relative = "editor",
    width = state.w,
    height = header_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row,
    style = "minimal",
    border = "single",
  }
  view_s.volt_win = vim.api.nvim_open_win(view_s.volt_buf, false, header_opts)
  vim.api.nvim_win_set_hl_ns(view_s.volt_win, state.ns)

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
  local container_opts = {
    relative = "editor",
    width = state.w,
    height = state.term.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h,
    style = "minimal",
    border = container_border,
  }
  view_s.container_win =
    vim.api.nvim_open_win(view_s.container_buf, false, container_opts)
  vim.api.nvim_win_set_hl_ns(view_s.container_win, state.term_ns)

  -- editor win
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
  view_s.win = vim.api.nvim_open_win(view_s.buf, true, editor_opts)
  vim.api.nvim_win_set_hl_ns(view_s.win, state.term_ns)

  -- footer win
  local footer_opts = {
    relative = "editor",
    width = state.w,
    height = state.footer.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h + state.term.h + border_h,
    style = "minimal",
    border = "single",
  }
  view_s.footer_win =
    vim.api.nvim_open_win(view_s.footer_buf, false, footer_opts)
  vim.api.nvim_win_set_hl_ns(view_s.footer_win, state.term_ns)

  -- volt events
  require("volt.events").add { view_s.volt_buf, view_s.footer_buf }

  vim.schedule(function()
    if view_s.win and vim.api.nvim_win_is_valid(view_s.win) then
      vim.api.nvim_set_current_win(view_s.win)
    end
  end)

  volt.run(view_s.volt_buf, { h = header_h, w = state.w })
  volt.run(view_s.footer_buf, { h = state.footer.h, w = state.w })

  require("cake.api").setup_cursor_events(view_s.buf)

  -- cleanup
  local function close_all()
    cleanup_view_state(view_s)
    if state.footer.cursor_timer then
      state.footer.cursor_timer:stop()
      state.footer.cursor_timer = nil
    end
  end

  local mappings_config = {
    bufs = { view_s.volt_buf, view_s.footer_buf },
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
  if opts.on_keymaps then opts.on_keymaps(view_s.buf) end

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

M.open = function()
  state.current_view = "commands"
  vim.cmd "stopinsert"

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    volt.close(state.volt_buf)
  end
  if
    state.cwd_edit.volt_buf
    and vim.api.nvim_buf_is_valid(state.cwd_edit.volt_buf)
  then
    volt.close(state.cwd_edit.volt_buf)
  end

  setup_view {
    view_state = state.edit,
    header = layout.header,
    footer = layout.edit_footer,
    buf_name = "Commands",
    on_setup = function(buf)
      local tab = state.tabs[state.active_tab]
      local cmds = (tab and tab.commands) or {}
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, cmds)
    end,
    on_keymaps = function(buf)
      vim.keymap.set(
        "n",
        "?",
        function() require("cake.help").open() end,
        { buffer = buf, silent = true, nowait = true }
      )
      vim.keymap.set(
        "n",
        "<Esc>",
        function() require("cake").open() end,
        { buffer = buf, silent = true, nowait = true }
      )
      vim.keymap.set(
        "n",
        state.config.mappings.edit_commands,
        function() require("cake").open() end,
        { buffer = buf, silent = true }
      )
      vim.keymap.set(
        "n",
        state.config.mappings.edit_cwd,
        function() M.open_cwd() end,
        { buffer = buf, silent = true, nowait = true }
      )
    end,
    on_save = function(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end
      local current_tab = state.tabs[state.active_tab]
      if current_tab then
        current_tab.commands = lines
        require("cake.utils").save_tabs()
        vim.notify("Commands saved!", vim.log.levels.INFO)
      end
    end,
  }
end

M.open_cwd = function()
  state.current_view = "commands"
  vim.cmd "stopinsert"

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    volt.close(state.volt_buf)
  end
  if state.edit.volt_buf and vim.api.nvim_buf_is_valid(state.edit.volt_buf) then
    volt.close(state.edit.volt_buf)
  end

  setup_view {
    view_state = state.cwd_edit,
    header = layout.header,
    footer = layout.cwd_footer,
    buf_name = "CWD",
    on_setup = function(buf)
      local tab = state.tabs[state.active_tab]
      local cwd = (tab and tab.cwd) or ""
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { cwd })
    end,
    on_keymaps = function(buf)
      vim.keymap.set(
        "n",
        "<Esc>",
        function() M.open() end,
        { buffer = buf, silent = true, nowait = true }
      )
      vim.keymap.set(
        "n",
        state.config.mappings.edit_cwd,
        function() M.open() end,
        { buffer = buf, silent = true, nowait = true }
      )
    end,
    on_save = function(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local new_cwd = lines[1] or ""
      local current_tab = state.tabs[state.active_tab]
      if current_tab then
        current_tab.cwd = new_cwd
        require("cake.utils").save_tabs()
        vim.notify("CWD saved!", vim.log.levels.INFO)
      end
    end,
  }
end

return M
