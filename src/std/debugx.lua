--- Extensions to the `debug` module.
--- @module std.debugx
local M = {}

local dbg_getupvalue = debug.getupvalue
local dbg_upvaluejoin = debug.upvaluejoin
local dbg_setupvalue = debug.setupvalue

local _ENV = M

--- Sets the environment to be used by a given function.
-- @tparam function f the function to get the environment of.
-- @tparam table env the new environment of the given function.
function setfenv(f, env)
  local up = 0
  local name
  repeat
    up = up + 1
    name = dbg_getupvalue(f, up)
  until name == '_ENV' or name == nil
  if name then
    dbg_upvaluejoin(f, up, function()
      return name
    end, 1)
    dbg_setupvalue(f, up, env)
  end
  return not not name
end

--- Gets the environment used by a given function.
-- @tparam function f the function to get the environment of.
-- @treturn table the environment of the given function.
function getfenv(f)
  local up = 0
  local name, env
  repeat
    up = up + 1
    name, env = dbg_getupvalue(f, up)
  until name == '_ENV' or name == nil
  return env
end

return M

