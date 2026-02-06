<h1 align="center">🍰 Cake</h1>

<p align="center">
  A Neovim plugin to simplify command management into<br>
  a piece of cake<br>
</p>

![cake-nb](https://github.com/user-attachments/assets/a48b5777-8f8b-4d75-a5f7-e53cd1701d08)
![cake-wb](https://github.com/user-attachments/assets/392f5f19-f3e9-4c4c-88df-497faf292af4)

> [!IMPORTANT]
> I celebrated my birthday by building the first iteration of this plugin! It’s still in its early stages, so I’d love to hear any feedbacks, issues, and contributions if you have any. 🍰

## Features

- **Tabbed Workflow**: Organize and run commands per tab.
- **Command Management**: Create, edit, and execute reusable command lists.
- **Session Persistence**: Save and restore tabs, commands, and working directories.
- **UI Layer**: Built on top of [`nvzone/volt`](https://github.com/nvzone/volt).

## Installation

**Requirements**:

- **Neovim** >= 0.9.0
- [`nvzone/volt`](https://github.com/nvzone/volt) (UI framework dependency)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

```lua
{
  "aikhe/cake.nvim",
  dependencies = "nvzone/volt",
  cmd = { "CakeToggle", "CakeFloat" },
  opts = {},
}
```

**Keymaps (Optional)**:

```lua
vim.keymap.set('n', '<leader>ef', function()
    require('cake').open({ mode = "float" })
end, { desc = 'Cake Float' })

vim.keymap.set('n', '<leader>ev', function()
    require('cake').open({ mode = "vertical" })
end, { desc = 'Cake Split Vertical' })

vim.keymap.set('n', '<leader>eh', function()
    require('cake').open({ mode = "horizontal" })
end, { desc = 'Cake Split Horizontal' })

vim.keymap.set('n', '<leader>et', function()
    require('cake').toggle()
end, { desc = 'Cake Toggle' })
```

## Default Config

```lua
require("cake").setup({
  terminal = "", -- Terminal defaults to bash & cmd
  title = " cake.nvim", -- Can be empty
  border = false,
  use_file_dir = false, -- Use file path as new tab default path
  mode = "float", -- "float", "splitv" (vertical), "splith" (horizontal)
  size = { h = 60, w = 50 }, -- Default float size
  split = { w = 50, h = 25 }, -- Default split sizes w: horizontal, h: vertical

  -- Override default mappings
  mappings = {
    new_tab = "n",
    edit_commands = "m",
    edit_cwd = ";",
    rerun = "r",
    kill_tab = "x",
    next_tab = "<C-n>",
    prev_tab = "<C-p>",
  },
})
```

## Mappings

These are the default mappings that are available when cake is open:

| Key     | Action            |
| ------- | ----------------- |
| `m`     | Edit commands     |
| `;`     | Edit commands cwd |
| `r`     | Rerun commands    |
| `n`     | New tab           |
| `x`     | Close tab         |
| `<C-n>` | Next tab          |
| `<C-p>` | Previous tab      |
| `1–9`   | Switch tabs       |
| `?`     | Help              |

> [!NOTE]
> Cake isn’t a terminal replacement. It’s designed for fast, seamless command execution rather than full terminal workflows like those provided by [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), [floaterm](https://github.com/nvzone/floaterm) or [tmux](https://github.com/tmux/tmux).
> It behaves more like [yeet.nvim](https://github.com/samharju/yeet.nvim), sending commands quickly to an existing terminal target.
