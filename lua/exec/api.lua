local M = {}

local state = require "exec.state"

---Opens a floating terminal window with exec.nvim
M.exec_float = function()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    require("exec.utils").new_term()
  end

  local conf = state.config
  local h = math.floor(vim.o.lines * (conf.size.h / 100))
  local w = math.floor(vim.o.columns * (conf.size.w / 100))

  local win_opts = {
    relative = "editor",
    width = w,
    height = h,
    row = (vim.o.lines - h) / 2 - 1,
    col = (vim.o.columns - w) / 2,
    style = "minimal",
    border = conf.border,
    title = " exec.nvim ",
    title_pos = "left",
  }

  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)
end

---Opens the terminal in a split window
M.exec_split = function()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    require("exec.utils").new_term()
  end

  vim.cmd(state.config.split_direction or "split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  if state.config.split_size then
    vim.cmd("resize " .. state.config.split_size)
  end
end

---Opens a floating window to edit the current list of commands
M.edit_cmds = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.commands)
  vim.api.nvim_set_option_value("modified", false, { buf = buf })

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "delete", { buf = buf })
  vim.api.nvim_buf_set_name(buf, "Exec Commands")

  local win_opts = {
    relative = "editor",
    width = 60,
    height = 10,
    col = (vim.o.columns - 60) / 2,
    row = (vim.o.lines - 10) / 2,
    style = "minimal",
    border = state.config.border,
    title = " Edit commands ",
    title_pos = "center",
  }

  state.edit_win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      state.commands = {}
      for _, line in ipairs(lines) do
        if line ~= "" then table.insert(state.commands, line) end
      end

      require("exec.utils").save_commands(state.commands)

      vim.api.nvim_set_option_value("modified", false, { buf = buf })
      print "commands saved"
    end,
  })

  vim.keymap.set(
    "n",
    "<Esc>",
    ":q<CR>",
    { buffer = buf, noremap = true, silent = true }
  )
end

return M
