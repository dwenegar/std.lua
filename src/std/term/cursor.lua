---
-- @module std.term.cursor

local M = {}

local io_type = io.type
local stdout = io.stdout

local function add_term_func(name, fmt)
  fmt = '\027[' .. fmt
  local function func(handle, ...)
    if io_type(handle) ~= 'file' then
      return func(stdout, handle, ...)
    end
    return handle:write(fmt:format(...))
  end
  M[name] = func
end

--- @function to
add_term_func('to', '%d;%dH')

--- @function up
add_term_func('up', '%d;A')

--- @function down
add_term_func('down', '%d;B')

--- @function right
add_term_func('right', '%d;C')

--- @function left
add_term_func('left', '%d;D')

--- @function save
add_term_func('save', 's')

--- @function restore
add_term_func('restore', 'u')

return M
