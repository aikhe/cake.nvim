local state = require "cake.state"

local M = {}

---@param direction "horizontal"|"vertical"
function M.open(direction)
  local terminal = require "cake.core.terminal"

  state.current_view = "term"
  terminal.init()

  if not state.term.buf then return end

  -- create split (container) with botright (user preferred)
  local split_cmd = direction == "horizontal" and "botright vsplit"
    or "botright split"
  vim.cmd(split_cmd)

  -- resize based on direction
  local size = direction == "horizontal" and state.config.split.w
    or state.config.split.h
  local resize_cmd = direction == "horizontal" and "vertical resize" or "resize"
  vim.cmd(resize_cmd .. " " .. size)

  -- setup container window
  state.term.container_win = vim.api.nvim_get_current_win()
  state.term.container_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.term.container_win, state.term.container_buf)

  -- apply background to container
  require("cake.ui.highlights").apply_split(state.term.container_win)

  -- configure container (hidden text)
  vim.api.nvim_set_option_value(
    "number",
    false,
    { win = state.term.container_win }
  )
  vim.api.nvim_set_option_value(
    "relativenumber",
    false,
    { win = state.term.container_win }
  )
  vim.api.nvim_set_option_value(
    "fillchars",
    "eob: ",
    { win = state.term.container_win }
  )
  vim.api.nvim_set_option_value("signcolumn", "no", { win = state.term.container_win })
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = state.term.container_win })

  -- calculate float size with padding
  local win_w = vim.api.nvim_win_get_width(state.term.container_win)
  local win_h = vim.api.nvim_win_get_height(state.term.container_win)
  local float_w = math.max(1, win_w - (state.xpad * 2))
  local float_h = math.max(1, win_h - (state.split_ypad * 2))

  -- create float (terminal) inside container
  state.term.win = vim.api.nvim_open_win(state.term.buf, true, {
    relative = "win",
    win = state.term.container_win,
    row = state.split_ypad,
    col = state.xpad,
    width = float_w,
    height = float_h,
    style = "minimal",
    border = "none",
  })

  -- apply highlights to terminal window
  require("cake.ui.highlights").apply_split(state.term.win)

  -- prevent line numbers in terminal window
  vim.api.nvim_set_option_value("number", false, { win = state.term.win })
  vim.api.nvim_set_option_value(
    "relativenumber",
    false,
    { win = state.term.win }
  )

  -- auto-resize float when container resizes
  vim.api.nvim_create_autocmd("WinResized", {
    pattern = tostring(state.term.container_win),
    callback = function()
      if
        state.term.container_win
        and vim.api.nvim_win_is_valid(state.term.container_win)
        and state.term.win
        and vim.api.nvim_win_is_valid(state.term.win)
      then
        local w = vim.api.nvim_win_get_width(state.term.container_win)
        local h = vim.api.nvim_win_get_height(state.term.container_win)
        vim.api.nvim_win_set_config(state.term.win, {
          width = math.max(1, w - (state.xpad * 2)),
          height = math.max(1, h - (state.split_ypad * 2)),
          row = state.split_ypad,
          col = state.xpad,
          relative = "win",
          win = state.term.container_win,
        })
      end
    end,
  })

  -- mask the separator line with a non-interactive float
  -- this avoids patching adjacent windows which causes side effects
  local function update_mask()
    if not state.term.container_win or not vim.api.nvim_win_is_valid(state.term.container_win) then return end
    
    local width = vim.api.nvim_win_get_width(state.term.container_win)
    local height = vim.api.nvim_win_get_height(state.term.container_win)
    
    local mask_opts = {
      relative = "win",
      win = state.term.container_win,
      style = "minimal",
      border = "none",
      zindex = 300, -- high enough to cover separator
      focusable = false, -- non-interactive
    }

    if direction == "horizontal" then
        -- vsplit: separator is to the left (since botright vsplit puts cake on right)
        -- wait, botright vsplit puts cake on RIGHT? yes.
        -- so separator is at col -1 relative to container.
        mask_opts.row = 0
        mask_opts.col = -1
        mask_opts.width = 1
        mask_opts.height = height
    else
        -- split: separator is above (since botright split puts cake on bottom)
        -- separator at row -1 relative to container.
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
        vim.api.nvim_set_option_value("winhighlight", "Normal:Normal", { win = state.mask_win })
        vim.api.nvim_set_option_value("fillchars", "eob: ", { win = state.mask_win })
    end
  end
  
  update_mask()

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

  -- cleanup logic
  local function cleanup()
      if state.mask_win and vim.api.nvim_win_is_valid(state.mask_win) then
        vim.api.nvim_win_close(state.mask_win, true)
      end
      state.mask_win = nil

      pcall(vim.api.nvim_del_augroup_by_name, "CakeContainerFocus")
      
      state.term.container_win = nil
      state.term.win = nil
      state.is_split = false
  end

  -- cleanup on close (watch float closure)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.win),
    once = true,
    callback = function()
      -- close container if float triggers close (and container still valid)
      if state.term.container_win and vim.api.nvim_win_is_valid(state.term.container_win) then
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
    end
  })

  vim.schedule(function()
    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_set_current_win(state.term.win)
    end
  end)
end

function M.close()
  -- explicit close: close float first, which triggers events to clean everything
  if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
    vim.api.nvim_win_close(state.term.win, true)
  elseif state.term.container_win and vim.api.nvim_win_is_valid(state.term.container_win) then
    vim.api.nvim_win_close(state.term.container_win, true)
  end
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

return M
