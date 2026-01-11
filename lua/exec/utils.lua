local M = {}

local api = vim.api
local state = require "exec.state"

M.reset_buf = function()
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf = nil
end

M.get_cmds_path = function()
  return vim.fn.stdpath "data" .. "/exec_commands.json"
end

M.load_commands = function()
  local path = M.get_cmds_path()
  local f = io.open(path, "r")

  if f then
    local content = f:read "*a"
    f:close()

    if content then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == "table" then return decoded end
    end
  end
  return {}
end

M.save_commands = function(cmds)
  local path = M.get_cmds_path()
  local f = io.open(path, "w")

  if f then
    f:write(vim.fn.json_encode(cmds))
    f:close()
  end
end

M.new_term = function()
  if #state.commands == 0 then state.commands = M.load_commands() end

  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    state.buf = api.nvim_create_buf(false, true)

    -- api.nvim_set_option_value("buflisted", false, { buf = state.buf })
    -- api.nvim_set_option_value("bufhidden", "hide", { buf = state.buf })
  end

  M.exec_in_buf(state.buf, state.commands, state.config.terminal, state.cwd)

  local opts = { buffer = state.buf, noremap = true, silent = true }

  vim.keymap.set("n", state.config.edit_key, function() M.edit_cmds() end, opts)

  vim.keymap.set(
    "n",
    "r",
    function() require("exec").open { reset = true } end,
    opts
  )

  vim.keymap.set(
    "t",
    "<Esc>",
    [[<C-\><C-n>]],
    { buffer = state.buf, noremap = true, silent = true }
  )
end

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

      M.save_commands(state.commands)

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

---Execute a command in a buffer, converting it to a terminal if needed
---@param buf integer Buffer number
---@param cmd string|table|nil Command to execute (if nil, opens a terminal)
---@param terminal string|nil Custom terminal executable
---@param cwd string|nil Directory to execute in
M.exec_in_buf = function(buf, cmd, terminal, cwd)
  if not buf or not api.nvim_buf_is_valid(buf) then return end

  if vim.bo[buf].buftype == "terminal" then return end

  local final_cmd = cmd
  if type(cmd) == "table" then
    local sep = " && "
    local term_check = terminal or state.config.terminal or vim.o.shell
    if term_check:find "powershell" or term_check:find "pwsh" then
      sep = "; "
    end
    final_cmd = table.concat(cmd, sep)
  end

  local term = terminal or state.config.terminal or vim.o.shell
  local job_cmd

  if final_cmd then
    local flag = "-c"

    if term:find "powershell" or term:find "pwsh" then
      flag = "-Command"
    elseif term:find "cmd" then
      flag = "/c"
    end

    job_cmd = { term, flag, final_cmd }
  else
    job_cmd = term
  end

  api.nvim_buf_call(buf, function()
    state.job_id = vim.fn.jobstart(job_cmd, {
      term = true,
      cwd = cwd,
      on_exit = function()
        vim.schedule(function()
          if api.nvim_buf_is_valid(buf) then
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

            -- local keys = { "i", "I", "a", "A", "o", "O", "c", "C", "s", "S" }
            -- for _, key in ipairs(keys) do
            --   vim.keymap.set("n", key, "<Nop>", { buffer = buf, nowait = true })
            -- end

            vim.keymap.set(
              "n",
              state.config.edit_key,
              function() M.edit_cmds() end,
              {
                buffer = buf,
                noremap = true,
                silent = true,
              }
            )

            vim.keymap.set(
              "t",
              "<Esc>",
              [[<C-\><C-n>]],
              { buffer = buf, noremap = true, silent = true }
            )

            vim.keymap.set(
              "n",
              "<Esc>",
              function() require("exec").toggle() end,
              { buffer = buf, noremap = true, silent = true }
            )
          end
        end)
      end,
    })
  end)
end

return M
