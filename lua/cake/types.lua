---@meta

---@class CakeMappings
---@field new_tab string
---@field edit_commands string
---@field edit_cwd string
---@field rerun string
---@field kill_tab string
---@field next_tab string
---@field prev_tab string
---@field esc_esc boolean

---@class CakeSize
---@field h number
---@field w number

---@class CakeSplitConfig
---@field w number
---@field h number

---@class CakeConfig
---@field terminal string
---@field title string
---@field border boolean
---@field size CakeSize
---@field split CakeSplitConfig
---@field use_file_dir boolean use file path as new tab default
---@field mode "float"|"split"|"splitv"|"splith"
---@field mappings CakeMappings
---@field custom_mappings? fun(buf: number, view: string)
