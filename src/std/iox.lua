--- Provides extension functions to the Lua `io` module.
-- @module std.iox

local M = setmetatable({}, {__index = io})

local io_open = io.open

local _ENV = M

--- Opens a text file, reads all lines of the file into a string array, and then closes the file.
-- @tparam string filename the name of the file to read.
-- @treturn table a string array containing all the lines of the file, or `nil` if the function fails.
-- @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function failed.
function read_lines(filename)
  local fh<close>, err = io_open(filename, 'r')
  if not fh then
    return nil, err
  end

  local t = {}
  while true do
    local line
    line, err = fh:read('l')
    if err or not line then
      break
    end
    t[#t + 1] = line
  end
  return t, err
end

--- Creates a new file, writes one or more strings to the file, and then closes the file.
-- @tparam string filename the name of the file to read.
-- @tparam table lines the lines to write to the file..
-- @treturn boolean `true` if the function succeeded, otherwise `false`.
-- @treturn string err `nil` if the function succeeded, otherwise an error message describing why the function failed.
function write_lines(filename, lines)
  local fh<close>, err = io_open(filename, 'w')
  if not fh then
    return false, err
  end

  local _
  for i = 1, #lines do
    _, err = fh:write(lines[i], '\n')
    if err then
      break
    end
  end
  return not err, err
end

local function read_file(filename, what)
  local fh<close>, err = io_open(filename, 'r')
  if not fh then
    return nil, err
  end

  local r
  r, err = fh:read(what)
  return r, err
end

--- Opens a file, reads the specified number of bytes, and then closes the file.
-- @tparam string filename the name of the file to read from.
-- @tparam integer n the number of bytes to read.
-- @treturn string the bytes read if the function succeeded, or `nil` if the functions fails.
-- @treturn string err `nil` if the function succeeded, otherwise an error message describing why the function failed.
function read_n(filename, n)
  return read_file(filename, n)
end

--- Opens a file, reads the whole file, and then closes the file.
-- @tparam string filename the name of the file to read from.
-- @treturn string the content of the file if the function succeeded, or `nil` if the functions fails.
-- @treturn string err `nil` if the function succeeded, otherwise an error message describing why the function failed.
function read_all(filename)
  return read_file(filename, 'a')
end

--- Creates a new file, write the contents to the file, and then closes the file.
-- @tparam string filename the name of the file to write to.
-- @tparam string content the content to write to the file.
-- @treturn boolean `true` if the function succeeded, otherwise `false`.
-- @treturn string err `nil` if the function succeeded, otherwise an error message describing why the function failed.
function write_all(filename, content)
  local fh<close>, err = io_open(filename, 'w')
  if not fh then
    return false, err
  end

  local _
  _, err = fh:write(content)
  return not err, err
end

return M

