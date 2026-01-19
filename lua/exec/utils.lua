local M = {}

local state = require "exec.state"

---returns the path to the tabs save file
---@return string Path to the tabs file
M.get_tabs_path = function() return vim.fn.stdpath "data" .. "/exec_tabs.json" end

---returns the current context CWD based on config
---@return string Path to the directory
M.get_context_cwd = function()
  local context_win = state.prev_win or vim.api.nvim_get_current_win()
  local ok, context_buf = pcall(vim.api.nvim_win_get_buf, context_win)
  if not ok then context_buf = vim.api.nvim_get_current_buf() end

  -- if we are in a terminal, don't use file dir (not meaningful)
  local buftype =
    vim.api.nvim_get_option_value("buftype", { buf = context_buf })

  if state.config.use_file_dir and buftype ~= "terminal" then
    local path = vim.api.nvim_buf_get_name(context_buf)
    if path ~= "" then return vim.fn.fnamemodify(path, ":p:h") end
  end

  return vim.fn.getcwd()
end

---loads tabs from the save file
---@return table List of tabs
M.load_tabs = function()
  local path = M.get_tabs_path()
  local f = io.open(path, "r")

  if f then
    local content = f:read "*a"
    f:close()

    if content and content ~= "" then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == "table" then return decoded end
    end
  end
  return {}
end

---saves the current tabs to save file
M.save_tabs = function()
  local path = M.get_tabs_path()
  local f = io.open(path, "w")

  if f then
    -- save cwd and commands per tab
    local save_data = {}
    for _, tab in ipairs(state.tabs) do
      table.insert(save_data, { cwd = tab.cwd, commands = tab.commands or {} })
    end
    f:write(vim.fn.json_encode(save_data))
    f:close()
  end
end

---returns the path to the commands JSON file
---@return string path to the commands file
M.get_cmds_path = function()
  return vim.fn.stdpath "data" .. "/exec_commands.json"
end

---loads commands from the persistent JSON file
---@return table list of commands
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

---saves the current list of commands to the persistent JSON file
---@param cmds table list of commands to save
M.save_commands = function(cmds)
  local path = M.get_cmds_path()
  local f = io.open(path, "w")

  if f then
    f:write(vim.fn.json_encode(cmds))
    f:close()
  end
end

M.get_shell_info = function(terminal)
  local shell = terminal or state.config.terminal
  if shell == nil or shell == "" then shell = vim.o.shell end

  local lower = shell:lower()
  local info = {
    path = shell,
    flag = "-c",
    sep = " && ",
  }

  if lower:find "powershell" or lower:find "pwsh" then
    info.flag = "-Command"
    info.sep = "\n"
  elseif lower:find "cmd" then
    info.flag = "/c"
    info.sep = " && "
  end

  return info
end

return M
