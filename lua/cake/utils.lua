local state = require "cake.state"

local M = {}

---returns the current context cwd based on config
---@return string
function M.get_context_cwd()
  local context_win = state.prev_win or vim.api.nvim_get_current_win()
  local ok, context_buf = pcall(vim.api.nvim_win_get_buf, context_win)
  if not ok then context_buf = vim.api.nvim_get_current_buf() end

  local buftype =
    vim.api.nvim_get_option_value("buftype", { buf = context_buf })

  if state.config.use_file_dir and buftype ~= "terminal" then
    local path = vim.api.nvim_buf_get_name(context_buf)
    if path ~= "" and not path:match "^%w+://" then
      return vim.fn.fnamemodify(path, ":p:h")
    end
  end

  return vim.fn.getcwd()
end

---split navigation
---@param buf number
function M.split_nav(buf)
  local ui = require "cake.ui"
  local map = vim.keymap.set
  local opts = { buffer = buf, noremap = true, silent = true }

  -- intercept <C-w> + direction
  map("n", "<C-w>", function()
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or not char then return end

    local dir = ({ h = "h", j = "j", k = "k", l = "l" })[char:lower()]
    if dir then
      ui.win.navigate(dir)
    else
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-w>" .. char, true, true, true),
        "n",
        false
      )
    end
  end, opts)

  -- apply user-defined navigation keys
  local dir_map = { left = "h", down = "j", up = "k", right = "l" }
  for dir_name, keys in pairs(state.config.split_nav or {}) do
    local wincmd_dir = dir_map[dir_name] or dir_name -- fallback for old config (h/j/k/l)
    for _, key in ipairs(keys) do
      map("n", key, function() ui.win.navigate(wincmd_dir) end, opts)
    end
  end
end

return M
