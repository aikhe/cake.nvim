local state = require "cake.state"
local map = vim.keymap.set

---@param buf number buffer to set keymaps on
---@param view "term"|"commands"|"cwd"|"help" current view type
return function(buf, view)
  local m = state.config.mappings
  local opts = { buffer = buf, noremap = true, silent = true }

  map("n", "?", function() require("cake.ui.help").open() end, opts)

  if view == "term" then
    map("n", "<Esc>", function() require("cake").toggle() end, opts)

    map("n", m.edit_commands, function()
      state.resetting = true
      require("cake.ui.edit").open()
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
        require("cake").open { reset = true }
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
      "<Esc>",
      [[<C-\><C-n>]],
      { buffer = buf, noremap = true, silent = true, nowait = true }
    )

    require("cake.core.terminal").setup_cursor_events(buf)
  elseif view == "commands" then
    map("n", "<Esc>", function() require("cake").open() end, opts)
    map("n", m.edit_commands, function() require("cake").open() end, opts)
    map(
      "n",
      m.edit_cwd,
      function() require("cake.ui.edit").open_cwd() end,
      opts
    )
  elseif view == "cwd" then
    map("n", "<Esc>", function() require("cake.ui.edit").open() end, opts)
    map("n", m.edit_cwd, function() require("cake.ui.edit").open() end, opts)
  elseif view == "help" then
    map("n", "q", function() require("cake.ui.help").close() end, opts)
    map("n", "<Esc>", function() require("cake.ui.help").close() end, opts)
  end

  if state.config.custom_mappings then
    state.config.custom_mappings(buf, view)
  end
end
