<p align="center">
  <br />
  <a href="https://github.com/aikhe/cake.nvim">
    <img width="300" alt="cake" src="https://github.com/user-attachments/assets/bb08fb17-873a-46c3-8bf1-e77c8f0201f1" />
  </a>
</p>

<br />

<img width="1400" alt="info" src="https://github.com/user-attachments/assets/58aa604d-5d8d-4875-b0d2-deaf5e8ad414" />

![cake-dark](https://github.com/user-attachments/assets/2b469903-28dd-4b00-8157-bd2ca5521a5d)
![cake-light](https://github.com/user-attachments/assets/2f95f004-6fc3-49e3-90d9-3b72d0ed0602)

# Cake

A Neovim plugin to simplify command management into a piece of cake<br>

## Features

- **Tabbed Workflow**: Organize and run commands per tab.
- **Command Management**: Create, edit, and execute reusable command lists.
- **Session Persistence**: Save and restore tabs, commands, and working directories.
- **UI Layer**: Built on top of [`nvzone/volt`](https://github.com/nvzone/volt).

> [!IMPORTANT]
> I celebrated my birthday by building the first iteration of this plugin! It’s still in its early stages, so I’d love to hear any feedbacks, issues, and contributions if you have any.

## Installation

**Requirements**:

- **Neovim** >= 0.9.0
- [`nvzone/volt`](https://github.com/nvzone/volt) (UI framework dependency)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

```lua
{
  "aikhe/cake.nvim",
  dependencies = "nvzone/volt",
  cmd = { "CakeToggle", "CakeFloat", "CakeSplitV", "CakeSplitH" },
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
