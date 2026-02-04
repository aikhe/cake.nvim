---@meta

---@class CakeMappings
---@field new_tab string
---@field edit_commands string
---@field edit_cwd string
---@field rerun string
---@field kill_tab string
---@field next_tab string
---@field prev_tab string

---@class CakeSize
---@field h number height percentage (0-100)
---@field w number width percentage (0-100)

---@class CakeConfig
---@field terminal string custom terminal command
---@field title string title shown in header
---@field border boolean show borders
---@field size CakeSize size configuration
---@field use_file_dir boolean use file path as new tab default
---@field mode "float"|"split" window mode
---@field mappings CakeMappings key mappings
---@field custom_mappings? fun(buf: number, view: string) user-defined custom mappings
