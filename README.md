<h1 align="center">🍰 Cake</h1>

<p align="center">
  A birthday gift to streamline workflow by making commands go woosh! in Neovim<br>
  <i>"As easy as a piece of cake"</i>
</p>

![Cake](https://github.com/user-attachments/assets/1bd0e633-0574-4cf3-a504-8797b51151b1)
![Cake Border](https://github.com/user-attachments/assets/a2282faf-0649-4f89-b619-69b0b1e9e00a)

> [!IMPORTANT]
> I celebrated my birthday by building the first iteration of this plugin! It’s currently in its early stages, so I’d love to hear your feedback or see your contributions. 🍰

## Features

- **Tabbed Workflow**: Organize and run commands per tab.
- **Command Management**: Create, edit, and execute reusable command lists.
- **Session Persistence**: Save and restore tabs, commands, and working directories.
- **Fast Reruns**: Rerun commands with a single keypress.
- **UI Layer**: Built on top of [`nvzone/volt`](https://github.com/nvzone/volt).

> [!NOTE]
> Cake.nvim is not a terminal replacement like [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), [floaterm](https://github.com/nvzone/floaterm) or [tmux](https://github.com/tmux/tmux); it handles lightweight command execution.

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

## Default Config

```lua
{
  terminal = "",
  title = " cake.nvim",
  border = false,
  size = { h = 60, w = 50 },
  use_file_dir = false, -- Use file path as new tab default path

  -- Override default mappings
  mappings = {
    edit_commands = "m",
    new_tab = "n",
    rerun = "r",
    kill_tab = "x",
    next_tab = "<C-n>",
    prev_tab = "<C-p>",
  },
}
```

## Mappings

These are the default mappings that are available when cake is open:

| Key     | Action         |
| ------- | -------------- |
| `n`     | New tab        |
| `x`     | Close tab      |
| `<C-n>` | Next tab       |
| `<C-p>` | Previous tab   |
| `1–9`   | Switch tabs    |
| `m`     | Edit commands  |
| `r`     | Rerun commands |
| `?`     | Help           |

Add Keymap:

```lua
keys = {
  {
    '<leader>cf',
    function()
      require('cake').open_float()
    end,
    desc = 'Cake Float',
  },
  {
    '<leader>ct',
    function()
      require('cake').toggle()
    end,
    desc = 'Cake Toggle',
  },
},
```
