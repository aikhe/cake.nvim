vim.api.nvim_create_user_command("Exec", function() require("exec").toggle() end, {})

require("exec").setup()
