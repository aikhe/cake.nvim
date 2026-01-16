local M = {}

local api = vim.api
local state = require "exec.state"

---Resets the terminal buffer by deleting it if it exists
M.reset_buf = function()
  for _, buf in ipairs(state.term_bufs) do
    if api.nvim_buf_is_valid(buf) then
      api.nvim_buf_delete(buf, { force = true })
    end
  end
  state.term_bufs = {}
  state.term_buf = nil
end

---Returns the path to the commands JSON file
---@return string Path to the commands file
M.get_cmds_path = function()
  return vim.fn.stdpath "data" .. "/exec_commands.json"
end

---Loads commands from the persistent JSON file
---@return table List of commands
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

---Saves the current list of commands to the persistent JSON file
---@param cmds table List of commands to save
M.save_commands = function(cmds)
  local path = M.get_cmds_path()
  local f = io.open(path, "w")

  if f then
    f:write(vim.fn.json_encode(cmds))
    f:close()
  end
end

---Initializes a new terminal buffer and sets up keymaps
---@param opts table? Options (e.g., force_new)
M.new_term = function(opts)
  opts = opts or {}
  if #state.commands == 0 then state.commands = M.load_commands() end

  if opts.force_new or not state.term_buf or not api.nvim_buf_is_valid(state.term_buf) then
    if not opts.force_new then state.term_bufs = {} end -- Clear if not specifically making a NEW session
    state.term_buf = api.nvim_create_buf(false, true)
    table.insert(state.term_bufs, state.term_buf)
  end

  local opts_map = { buffer = state.term_buf, noremap = true, silent = true }

  vim.keymap.set("n", state.config.edit_key, function() require("exec.api").edit_cmds() end, opts_map)
  
  -- New terminal session mapping
  vim.keymap.set("n", "t", function()
    state.resetting = true
    M.new_term { force_new = true }
    if state.term_win and api.nvim_win_is_valid(state.term_win) then
      api.nvim_win_set_buf(state.term_win, state.term_buf)
      -- Spawn a shell (nil command)
      M.exec_in_buf(state.term_buf, nil, state.config.terminal, state.cwd)
    else
      require("exec").open()
    end
  end, opts_map)

  vim.keymap.set(
    "n",
    "r",
    function()
      if #state.commands > 0 then
        state.resetting = true
        require("exec").open { reset = true }
      else
        print "No commands to rerun!"
      end
    end,
    opts_map
  )

  vim.keymap.set(
    "t",
    "<Esc>",
    [[<C-\><C-n>]],
    { buffer = state.term_buf, noremap = true, silent = true, nowait = true }
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
    if #cmd == 0 then
      final_cmd = nil
    else
      local sep = " && "
      local term_check = terminal or state.config.terminal or vim.o.shell
      if term_check:find "powershell" or term_check:find "pwsh" then
        sep = "; "
      end
      final_cmd = table.concat(cmd, sep)
    end
  end

  local term = terminal or state.config.terminal or vim.o.shell
  local job_cmd

  if final_cmd and final_cmd ~= "" then
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
              function() require("exec.api").edit_cmds() end,
              {
                buffer = buf,
                noremap = true,
                silent = true,
              }
            )

            vim.keymap.set(
              "n",
              "t",
              function()
                state.resetting = true
                M.new_term { force_new = true }
                if state.term_win and api.nvim_win_is_valid(state.term_win) then
                  api.nvim_win_set_buf(state.term_win, state.term_buf)
                  -- Spawn a shell (nil command)
                  M.exec_in_buf(state.term_buf, nil, state.config.terminal, state.cwd)
                else
                  require("exec").open()
                end
              end,
              { buffer = buf, noremap = true, silent = true }
            )
            
            vim.keymap.set(
              "n",
              "r",
              function()
                if #state.commands > 0 then
                  state.resetting = true
                  require("exec").open { reset = true }
                else
                  print "No commands to rerun!"
                end
              end,
              { buffer = buf, noremap = true, silent = true }
            )

            vim.keymap.set(
              "t",
              "<Esc>",
              [[<C-\><C-n>]],
              { buffer = buf, noremap = true, silent = true, nowait = true }
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
