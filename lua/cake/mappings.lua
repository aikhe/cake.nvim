local state = require "cake.state"
local ui = require "cake.ui"
local map = vim.keymap.set

---@param buf number buffer to set keymaps on
---@param view "term"|"commands"|"cwd"|"help" current view type
return function(buf, view)
  local m = state.config.mappings
  local opts = { buffer = buf, noremap = true, silent = true }

  map("n", "?", function() ui.help.open() end, opts)

  if view == "term" then
    map("n", "<Esc>", function() require("cake").toggle() end, opts)

    map("n", m.edit_commands, function()
      state.resetting = true
      ui.edit.open()
    end, opts)

    map(
      "n",
      m.new_tab,
      function() require("cake.core.tabs").create_new() end,
      opts
    )

    map("n", m.kill_tab, function() require("cake.core.tabs").kill() end, opts)

    map("n", m.rerun, function()
      local tab = state.tabs[state.active_tab]
      if tab then
        state.resetting = true
        if state.is_split then
          -- rerun in split: reset terminal buffer and rerun commands
          local old_buf = require("cake.core.terminal").reset_buf { defer_delete = true }
          
          -- attach new buffer to split window
          if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
            vim.api.nvim_win_set_buf(state.term.win, state.term.buf)
            -- disable line numbers on new buffer
            vim.api.nvim_set_option_value("number", false, { win = state.term.win })
            vim.api.nvim_set_option_value("relativenumber", false, { win = state.term.win })
            
            -- re-apply mappings to new buffer
            require "cake.mappings"(state.term.buf, "term")
          end
          
          -- delete old buffer now that window has new buffer
          if old_buf and vim.api.nvim_buf_is_valid(old_buf) then
            vim.api.nvim_buf_delete(old_buf, { force = true })
          end

          require("cake.core.terminal").run_in_buf(
            state.term.buf,
            tab.commands or {},
            state.config.terminal,
            state.cwd
          )
        else
          require("cake").open { reset = true }
        end
      end
    end, opts)

    map("n", m.next_tab, function() require("cake.core.tabs").next() end, opts)
    map("n", m.prev_tab, function() require("cake.core.tabs").prev() end, opts)

    for i = 1, 9 do
      map(
        "n",
        tostring(i),
        function() require("cake.core.tabs").switch(i) end,
        opts
      )
    end

    vim.api.nvim_buf_call(buf, function()
      vim.cmd [[cnoreabbrev <expr> <buffer> w getcmdtype() == ':' && getcmdline() ==# 'w' ? 'lua require"cake.core.tabs".save_current()' : 'w']]
      vim.cmd [[cnoreabbrev <expr> <buffer> w! getcmdtype() == ':' && getcmdline() ==# 'w!' ? 'lua require"cake.core.tabs".save_current()' : 'w!']]
      vim.cmd [[cnoreabbrev <expr> <buffer> write getcmdtype() == ':' && getcmdline() ==# 'write' ? 'lua require"cake.core.tabs".save_current()' : 'write']]
    end)

    map(
      "t",
      m.esc_esc and "<Esc><Esc>" or "<Esc>",
      [[<C-\><C-n>]],
      { buffer = buf, noremap = true, silent = true, nowait = true }
    )

    require("cake.core.terminal").setup_cursor_events(buf)
    
    -- split navigation from float
    local nav_dirs = { "h", "j", "k", "l" }
    for _, dir in ipairs(nav_dirs) do
      map("n", "<C-w>" .. dir, function()
        ui.split.navigate(dir)
      end, opts)
      -- support user custom keybinds (ctrl+hjkl) directly
      map("n", "<C-" .. dir .. ">", function()
        ui.split.navigate(dir)
      end, opts)
    end
  elseif view == "commands" then
    local function back_to_term()
      if state.is_split then
        ui.edit.back_to_split_term()
      else
        require("cake").open()
      end
    end
    map("n", "<Esc>", back_to_term, opts)
    map("n", m.edit_commands, back_to_term, opts)
    map(
      "n",
      m.edit_cwd,
      function() ui.edit.open_cwd() end,
      opts
    )
  elseif view == "cwd" then
    map("n", "<Esc>", function() ui.edit.open() end, opts)
    map("n", m.edit_cwd, function() ui.edit.open() end, opts)
  elseif view == "help" then
    map("n", "q", function() ui.help.close() end, opts)
    map("n", "<Esc>", function() ui.help.close() end, opts)
  end

  if state.config.custom_mappings then
    state.config.custom_mappings(buf, view)
  end
end
