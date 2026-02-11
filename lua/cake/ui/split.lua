local state = require "cake.state"
local highlights = require "cake.ui.highlights"
local volt = require "volt"
local layout = require "cake.ui.layout"

local M = {}

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

-- covers the split separator line
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
    zindex = 300,
    focusable = false,
  }

  if direction == "splith" then
    mask_opts.row = 0
    mask_opts.col = -1
    mask_opts.width = 1
    mask_opts.height = height
  else
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

local function cleanup_split()
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

---@param direction "splith"|"splitv"
function M.open(direction)
  state.split.direction = direction
  state.is_split = true

  local split_cmd = direction == "splith" and "botright vsplit"
    or "botright split"
  vim.cmd(split_cmd)

  local size = state.split.last_sizes[direction]
    or (direction == "splith" and state.config.split.w or state.config.split.h)
  local resize_cmd = direction == "splith" and "vertical resize" or "resize"
  vim.cmd(resize_cmd .. " " .. size)

  state.term.container_win = vim.api.nvim_get_current_win()
  state.term.container_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.term.container_win, state.term.container_buf)

  highlights.apply_split(state.term.container_win)
  vim.api.nvim_win_set_hl_ns(state.term.container_win, state.term_ns)

  configure_minimal_win(
    state.term.container_win,
    { fillchars = true, columns = true }
  )

  local win_w = vim.api.nvim_win_get_width(state.term.container_win)
  local border_h = 2
  local border_offset = 1
  state.w = win_w - border_h

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

  require("volt.events").add { state.header.buf }
  volt.run(state.header.buf, { h = state.h, w = win_w - border_h })

  local win_h = vim.api.nvim_win_get_height(state.term.container_win)
  local float_w = math.max(1, win_w - (state.xpad * 2) - border_h)
  local header_total_h = state.h + border_h
  local float_h =
    math.max(1, win_h - header_total_h - (state.split_ypad * 2) + 1)

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
  vim.api.nvim_win_set_hl_ns(state.term.win, state.term_ns)
  configure_minimal_win(state.term.win, { fillchars = true })

  -- auto-resize: sync float dimensions to container and redirect float resizes
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
      local hdr_h = state.h + border_h

      -- redirect: if user resized the float, apply delta to container
      if float_resized then
        local fw = vim.api.nvim_win_get_width(state.term.win)
        local fh = vim.api.nvim_win_get_height(state.term.win)

        local ideal_w = math.max(1, cw - (state.xpad * 2) - border_h)
        local ideal_h = math.max(1, ch - hdr_h - (state.split_ypad * 2) + 1)

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

      state.split.last_sizes[direction] = (direction == "splith") and cw or ch

      state.w = cw - border_h

      if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
        vim.api.nvim_win_set_config(state.header.win, {
          width = cw - border_h,
          height = state.h,
          row = 0,
          col = 0,
          relative = "win",
          win = state.term.container_win,
        })
        vim.api.nvim_set_option_value(
          "modifiable",
          true,
          { buf = state.header.buf }
        )
        volt.run(state.header.buf, { h = state.h, w = cw - border_h })
      end

      vim.api.nvim_win_set_config(state.term.win, {
        width = math.max(1, cw - (state.xpad * 2) - border_h),
        height = math.max(1, ch - hdr_h - (state.split_ypad * 2) + 1),
        row = hdr_h + state.split_ypad - 1,
        col = state.xpad + border_offset,
        relative = "win",
        win = state.term.container_win,
      })

      update_mask(direction)
    end,
  })

  update_mask(direction)
  require("cake.core.terminal").ensure_running()
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
          if vim.api.nvim_get_current_win() == state.term.container_win then
            if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
              vim.api.nvim_set_current_win(state.term.win)
            end
          end
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.win),
    once = true,
    callback = function()
      if
        state.term.container_win
        and vim.api.nvim_win_is_valid(state.term.container_win)
      then
        vim.api.nvim_win_close(state.term.container_win, true)
      end
      cleanup_split()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.container_win),
    once = true,
    callback = function()
      if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
        vim.api.nvim_win_close(state.term.win, true)
      end
      cleanup_split()
    end,
  })
end

return M
