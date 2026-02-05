-- central hub for all ui modules
-- usage: require("cake.ui").float.open() or require("cake.ui").split.open()

local M = {}

-- lazy load submodules to avoid circular dependencies
M.float = require "cake.ui.float"
M.split = require "cake.ui.split"
M.edit = require "cake.ui.edit"
M.help = require "cake.ui.help"
M.layout = require "cake.ui.layout"
M.components = require "cake.ui.components"
M.highlights = require "cake.ui.highlights"

-- backward compatible entry point
M.open = M.float.open

return M
