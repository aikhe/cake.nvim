vim.api.nvim_create_user_command(
  "CakeToggle",
  function() require("cake").toggle() end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeFloat",
  function() require("cake").open { mode = "float" } end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitH",
  function() require("cake").open { mode = "splith" } end,
  {}
)

vim.api.nvim_create_user_command(
  "CakeSplitV",
  function() require("cake").open { mode = "splitv" } end,
  {}
)

vim.api.nvim_create_user_command("CakeRun", function(cmd_opts)
  local opts = {}

  for _, arg in ipairs(cmd_opts.fargs) do
    local key, val = arg:match "^(%w+)=(.+)$"
    if key == "tab" then
      opts.tab = tonumber(val)
    elseif key == "mode" then
      opts.mode = val
    end
  end

  require("cake").run(opts)
end, {
  nargs = "*",
  complete = function(_, line)
    local completions = {}
    if not line:match "tab=" then table.insert(completions, "tab=") end
    if not line:match "mode=" then
      for _, m in ipairs { "mode=float", "mode=splitv", "mode=splith" } do
        table.insert(completions, m)
      end
    end
    return completions
  end,
})
