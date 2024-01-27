local M = setmetatable({}, {
  __index = require 'std.fs.native'
})

local _ENV = M

return M
