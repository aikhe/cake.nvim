local state = require "cake.state"

local M = {}

---returns the path to the tabs save file
---@return string
function M.get_tabs_path() return vim.fn.stdpath "data" .. "/cake_tabs.json" end

---loads tabs from the save file
---@return CakeTab[]
function M.load_tabs()
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
function M.save_tabs()
  local path = M.get_tabs_path()
  local f = io.open(path, "w")

  if f then
    local save_data = {}
    for _, tab in ipairs(state.tabs) do
      table.insert(save_data, { cwd = tab.cwd, commands = tab.commands or {} })
    end
    f:write(vim.fn.json_encode(save_data))
    f:close()
  end
end

---returns the path to the commands json file
---@return string
function M.get_cmds_path() return vim.fn.stdpath "data" .. "/cake_commands.json" end

---loads commands from the persistent json file
---@return string[]
function M.load_commands()
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

---saves the current list of commands to the persistent json file
---@param cmds string[]
function M.save_commands(cmds)
  local path = M.get_cmds_path()
  local f = io.open(path, "w")

  if f then
    f:write(vim.fn.json_encode(cmds))
    f:close()
  end
end

return M
