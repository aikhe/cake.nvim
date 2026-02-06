local state = require "cake.state"
local highlights = require "cake.ui.highlights"

local M = {}

-- configure window for minimal ui appearance
local function configure_minimal_win(win, opts)
  opts = opts or {}
  local o = { win = win }
  vim.api.nvim_set_option_value("number", false, o)
  vim.api.nvim_set_option_value("relativenumber", false, o)
  if opts.fillchars then
    vim.api.nvim_set_option_value("fillchars", "eob: ", o)
  end
  if opts.columns then
    vim.api.nvim_set_option_value("signcolumn", "no", o)
    vim.api.nvim_set_option_value("foldcolumn", "0", o)
  end
end

-- this thing covers the split seperator line, it works but still thiking about a better way
local function update_mask(direction)
  if state.config.border then return end
  if
    not state.term.container_win
    or not vim.api.nvim_win_is_valid(state.term.container_win)
  then
    return
  end

  local width = vim.api.nvim_win_get_width(state.term.container_win)
  local height = vim.api.nvim_win_get_height(state.term.container_win)

  local mask_opts = {
    relative = "win",
    win = state.term.container_win,
    style = "minimal",
    border = "none",
    zindex = 300, -- high enough to cover separator T~T
    focusable = false, -- non-interactive
  }

  if direction == "horizontal" then
    -- vsplit: separator is to the left (since botright vsplit puts cake on right)
    mask_opts.row = 0
    mask_opts.col = -1
    mask_opts.width = 1
    mask_opts.height = height
  else
    -- split: separator is above (since botright split puts cake on bottom)
    mask_opts.row = -1
    mask_opts.col = 0
    mask_opts.width = width
    mask_opts.height = 1
  end

  if state.mask_win and vim.api.nvim_win_is_valid(state.mask_win) then
    vim.api.nvim_win_set_config(state.mask_win, mask_opts)
  else
    local mask_buf = vim.api.nvim_create_buf(false, true)
    state.mask_win = vim.api.nvim_open_win(mask_buf, false, mask_opts)
    vim.api.nvim_set_option_value(
      "winhighlight",
      "Normal:Normal",
      { win = state.mask_win }
    )
    vim.api.nvim_set_option_value(
      "fillchars",
      "eob: ",
      { win = state.mask_win }
    )
  end
end

-- cleanup logic
local function cleanup()
  if state.mask_win and vim.api.nvim_win_is_valid(state.mask_win) then
    vim.api.nvim_win_close(state.mask_win, true)
  end
  state.mask_win = nil

  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    vim.api.nvim_win_close(state.header.win, true)
  end
  if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
    require("volt").close(state.header.buf)
  end
  state.header.win, state.header.buf = nil, nil

  pcall(vim.api.nvim_del_augroup_by_name, "CakeContainerFocus")
  pcall(vim.api.nvim_del_augroup_by_name, "CakeSplit")

  state.term.container_win = nil
  state.term.win = nil
  state.is_split = false
end

---@param direction "horizontal"|"vertical"
function M.open(direction)
  local volt = require "volt"
  local layout = require "cake.ui.layout"
  local terminal = require "cake.core.terminal"

  -- populate highlight namespace for tabs/title
  require "volt.highlights"
  require "cake.ui.highlights"(state.ns)

  state.current_view = "term"
  terminal.init()

  if not state.term.buf then return end

  -- create split (container) with botright (user preferred)
  local split_cmd = direction == "horizontal" and "botright vsplit"
    or "botright split"
  vim.cmd(split_cmd)

  -- start size based on direction
  local size = state.split.last_sizes[direction]
    or (
      direction == "horizontal" and state.config.split.w or state.config.split.h
    )
  local resize_cmd = direction == "horizontal" and "vertical resize" or "resize"
  vim.cmd(resize_cmd .. " " .. size)

  -- setup container window
  state.term.container_win = vim.api.nvim_get_current_win()
  state.term.container_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.term.container_win, state.term.container_buf)

  -- apply background to container
  highlights.apply_split(state.term.container_win)

  -- configure container (hidden text)
  configure_minimal_win(
    state.term.container_win,
    { fillchars = true, columns = true }
  )

  -- setup header (reuse float logic since im freaking lazy rn)
  local win_w = vim.api.nvim_win_get_width(state.term.container_win)
  local border_h = 2
  local border_offset = 1
  state.w = win_w - border_h -- ensure layout uses internal split width

  state.header.buf = vim.api.nvim_create_buf(false, true)
  volt.gen_data {
    {
      buf = state.header.buf,
      layout = layout.header,
      xpad = state.xpad,
      ns = state.ns,
    },
  }
  state.h = require("volt.state")[state.header.buf].h

  local border_style = { " ", " ", " ", " ", " ", " ", " ", " " }

  -- header win (float)
  state.header.win = vim.api.nvim_open_win(state.header.buf, false, {
    relative = "win",
    win = state.term.container_win,
    width = win_w - border_h,
    height = state.h,
    col = 0,
    row = 0,
    style = "minimal",
    border = border_style,
  })
  vim.api.nvim_win_set_hl_ns(state.header.win, state.ns)

  -- finalize header UI
  require("volt.events").add { state.header.buf }
  volt.run(state.header.buf, { h = state.h, w = win_w - border_h })

  -- calculate term float size with padding
  local win_h = vim.api.nvim_win_get_height(state.term.container_win)
  local float_w = math.max(1, win_w - (state.xpad * 2) - border_h)
  local header_total_h = state.h + border_h
  local float_h =
    math.max(1, win_h - header_total_h - (state.split_ypad * 2) + 1)

  -- term window (float)
  state.term.win = vim.api.nvim_open_win(state.term.buf, true, {
    relative = "win",
    win = state.term.container_win,
    row = header_total_h + state.split_ypad - 1,
    col = state.xpad + border_offset,
    width = float_w,
    height = float_h,
    style = "minimal",
    border = "none",
  })
  highlights.apply_split(state.term.win)

  configure_minimal_win(state.term.win)

  -- auto-resize logic (handles container resize and redirects float resize)
  local split_group = vim.api.nvim_create_augroup("CakeSplit", { clear = true })
  vim.api.nvim_create_autocmd("WinResized", {
    group = split_group,
    callback = function()
      if
        not state.term.container_win
        or not vim.api.nvim_win_is_valid(state.term.container_win)
        or not state.term.win
        or not vim.api.nvim_win_is_valid(state.term.win)
      then
        return
      end

      local resized_wins = vim.v.event.windows or {}
      local float_resized = false
      local container_resized = false
      for _, w in ipairs(resized_wins) do
        if w == state.term.win then float_resized = true end
        if w == state.term.container_win then container_resized = true end
      end

      if not float_resized and not container_resized then return end

      local cw = vim.api.nvim_win_get_width(state.term.container_win)
      local ch = vim.api.nvim_win_get_height(state.term.container_win)
      local header_h = state.h + border_h

      -- redirect: if user resized the float (via keybinds/commands), apply delta to container
      if float_resized then
        local fw = vim.api.nvim_win_get_width(state.term.win)
        local fh = vim.api.nvim_win_get_height(state.term.win)

        local ideal_w = math.max(1, cw - (state.xpad * 2) - border_h)
        local ideal_h = math.max(1, ch - header_h - (state.split_ypad * 2) + 1)

        local dx = fw - ideal_w
        local dy = fh - ideal_h

        if dx ~= 0 then
          vim.api.nvim_win_set_width(state.term.container_win, cw + dx)
        end
        if dy ~= 0 then
          vim.api.nvim_win_set_height(state.term.container_win, ch + dy)
        end

        cw = vim.api.nvim_win_get_width(state.term.container_win)
        ch = vim.api.nvim_win_get_height(state.term.container_win)
      end

      -- save last split size
      state.split.last_sizes[direction] = (direction == "horizontal") and cw
        or ch

      -- sync all windows to container
      state.w = cw - border_h

      -- update header
      if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
        vim.api.nvim_win_set_config(state.header.win, {
          width = cw - border_h,
          height = state.h,
          row = 0,
          col = 0,
          relative = "win",
          win = state.term.container_win,
        })
        -- ensure modifiable for volt redraw
        vim.api.nvim_set_option_value(
          "modifiable",
          true,
          { buf = state.header.buf }
        )
        volt.run(state.header.buf, { h = state.h, w = cw - border_h })
      end

      -- update terminal
      vim.api.nvim_win_set_config(state.term.win, {
        width = math.max(1, cw - (state.xpad * 2) - border_h),
        height = math.max(1, ch - header_h - (state.split_ypad * 2) + 1),
        row = header_h + state.split_ypad - 1,
        col = state.xpad + border_offset,
        relative = "win",
        win = state.term.container_win,
      })

      -- update mask
      update_mask(direction)
    end,
  })

  update_mask(direction)

  -- run terminal if needed
  if vim.bo[state.term.buf].buftype ~= "terminal" then
    local tab = state.tabs[state.active_tab]
    terminal.run_in_buf(
      state.term.buf,
      tab and tab.commands or {},
      state.config.terminal,
      state.cwd
    )
  end

  -- setup keybinds
  require "cake.mappings"(state.term.buf, "term")

  -- auto-focus float when entering container
  local focus_group =
    vim.api.nvim_create_augroup("CakeContainerFocus", { clear = true })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = focus_group,
    callback = function()
      if
        state.term.container_win
        and vim.api.nvim_get_current_win() == state.term.container_win
      then
        vim.schedule(function()
          -- check if we are still in container (navigation might have moved us out)
          if vim.api.nvim_get_current_win() == state.term.container_win then
            if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
              vim.api.nvim_set_current_win(state.term.win)
            end
          end
        end)
      end
    end,
  })

  -- cleanup on close (watch float closure)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.win),
    once = true,
    callback = function()
      -- close container if float triggers close (and container still valid)
      if
        state.term.container_win
        and vim.api.nvim_win_is_valid(state.term.container_win)
      then
        vim.api.nvim_win_close(state.term.container_win, true)
      end
      cleanup()
    end,
  })

  -- also watch container closure (user :q on split)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.container_win),
    once = true,
    callback = function()
      -- if container closes, force close float immediately
      if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
        vim.api.nvim_win_close(state.term.win, true)
      end
      cleanup()
    end,
  })

  vim.schedule(function()
    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_set_current_win(state.term.win)
    end
  end)
end

---navigate from the split container
---@param direction "h"|"j"|"k"|"l"
function M.navigate(direction)
  if
    not state.term.container_win
    or not vim.api.nvim_win_is_valid(state.term.container_win)
  then
    vim.cmd("wincmd " .. direction)
    return
  end

  local current_float = vim.api.nvim_get_current_win()

  -- switch to container to perform navigation
  vim.api.nvim_set_current_win(state.term.container_win)
  vim.cmd("wincmd " .. direction)

  -- check if we moved
  local new_win = vim.api.nvim_get_current_win()
  if new_win == state.term.container_win then
    -- didn't move (hit edge), restore focus to float
    vim.api.nvim_set_current_win(current_float)
  end
end

function M.close()
  -- enforce persistence before closing
  if state.term.buf and vim.api.nvim_buf_is_valid(state.term.buf) then
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.term.buf })
  end

  -- explicit close: close float first, which triggers events to clean everything
  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_close(state.term.win, true)
  elseif state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    vim.api.nvim_win_close(state.header.win, true)
  elseif
    state.term.container_win
    and vim.api.nvim_win_is_valid(state.term.container_win)
  then
    vim.api.nvim_win_close(state.term.container_win, true)
  end
end

return M
