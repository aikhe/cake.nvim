# 🍰 Cake

A birthday gift built to streamline my workflow and make commands go woosh, as easy as a piece of cake.

## Installation

```lua
{
  "aikhe/bday",
  dependencies = "nvzone/volt",
  cmd = { "BdayToggle", "BdayFloat" },
  opts = {},
}
```

## Configuration

```lua
{
  terminal = "",
  border = false,
  size = { h = 60, w = 50 },
  use_file_dir = false, -- use file path as new tab default path

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

## Mappings (Default)

- `n`: New tab
- `x`: Close tab
- `m`: Edit commands
- `r`: Rerun commands
- `<C-n>`: Next tab
- `<C-p>`: Previous tab
- `1-9`: Switch tabs
- `?`: Help
- `<Esc>`: Toggle/Close
