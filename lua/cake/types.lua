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
---@field h number Height percentage (0-100)
---@field w number Width percentage (0-100)

---@class CakeConfig
---@field terminal string Custom terminal command
---@field title string Title shown in header
---@field border boolean Show borders
---@field size CakeSize Size configuration
---@field use_file_dir boolean Use file path as new tab default
---@field mode "float"|"split" Window mode
---@field mappings CakeMappings Key mappings
---@field custom_mappings? fun(buf: number, view: string) User-defined custom mappings
