---@meta

---@class CakeTab
---@field id number tab identifier
---@field buf number buffer handle
---@field cwd string working directory
---@field commands string[] list of commands

---@class CakeWindowState
---@field buf number|nil buffer handle
---@field win number|nil window handle

---@class CakeHeaderState : CakeWindowState

---@class CakeTermState : CakeWindowState
---@field h number height
---@field job_id number|nil job id
---@field container_win number|nil container window handle (split mode)
---@field container_buf number|nil container buffer handle (split mode)

---@class CakeFooterState : CakeWindowState
---@field h number height
---@field cursor_timer userdata|nil timer for cursor updates

---@class CakeEditState : CakeWindowState
---@field container_buf number|nil
---@field container_win number|nil
---@field header_buf number|nil
---@field header_win number|nil
---@field footer_buf number|nil
---@field footer_win number|nil

---@class CakeHelpState
---@field buf number|nil
---@field return_view "term"|"commands"|nil
---@field prev_buf number|nil

---@class CakeSplitState
---@field direction "splith"|"splitv"|nil
---@field last_sizes { splith: number|nil, splitv: number|nil }

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
---@field use_file_dir boolean
---@field mode "float"|"splitv"|"splith"
---@field mappings CakeMappings
---@field split_nav? table<string, string[]>
---@field custom_mappings? fun(buf: number, view: string)

---@class CakeState
---@field ns number namespace for UI highlights
---@field term_ns number namespace for terminal highlights
---@field xpad number horizontal padding
---@field ypad number vertical padding (floating)
---@field split_ypad number vertical padding (split mode)
---@field w number current layout width
---@field h number current layout height
---@field current_view "term"|"commands"|"edit"|"help" current active view
---@field last_mode string|nil last nvim mode
---@field is_split boolean whether we are in split mode
---@field split CakeSplitState split specific state
---@field cwd string|nil current working directory
---@field resetting boolean flags to prevent loops during reset
---@field setup_done boolean whether setup has been called
---@field prev_win number|nil window handle before opening cake
---@field mask_win number|nil window handle for split separator mask
---@field header CakeHeaderState
---@field tabs CakeTab[]
---@field active_tab number index of the active tab
---@field term CakeTermState
---@field container CakeWindowState main container window
---@field footer CakeFooterState
---@field edit CakeEditState
---@field cwd_edit CakeEditState
---@field help CakeHelpState
---@field config CakeConfig merged configuration
