local M = {}

local api = require "exec.api"
local state = require "exec.state"
local utils = require "exec.utils"

M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})

  if state.config.mapping then require "exec.mappings"() end
end

M.open = function(opts)
  opts = opts or {}
  state.last_mode = opts.mode or state.last_mode or state.config.mode

  if opts.reset then utils.reset_buf() end

  local current_file = vim.fn.expand "%:p"
  if current_file ~= "" then
    state.cwd = vim.fn.fnamemodify(current_file, ":h")
  else
    state.cwd = vim.fn.getcwd()
  end

  print(state.cwd)

  state.prev_win = vim.api.nvim_get_current_win()
  utils.new_term()

  if state.last_mode == "float" then
    api.exec_float()
  else
    api.exec_split()
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(state.win),
      once = true,

      callback = function()
        if state.edit_win and vim.api.nvim_win_is_valid(state.edit_win) then
          vim.api.nvim_win_close(state.edit_win, true)
        end

        state.edit_win = nil
      end,
    })
  end
end

M.edit_cmds = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.commands)

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
    title = "edit commands",
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

      utils.save_commands(state.commands)

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

M.toggle = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)

    if vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end

    state.win = nil
  else
    M.open { mode = state.last_mode }
  end
end

return M
