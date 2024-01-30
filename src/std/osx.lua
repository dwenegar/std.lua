--- Provides extension functions to the Lua `os` module.
-- @module std.osx

local M = setmetatable({}, {__index = os})

local io = require 'std.iox'
local path = require 'std.path'

local os_execute = os.execute
local os_getenv = os.getenv
local os_remove = os.remove
local tbl_concat = table.concat

local _ENV = M

--- Executes a given command
-- @tparam CommandContext cmd the command to execute
-- @treturn boolean `true` if the function succeeded, otherwise `false`.
-- @treturn string the output of the command if the function succeeded, otherwise `nil`.
-- @treturn string the error output of the command if the function succeeded, otherwise `nil`.
function exec(cmd)
  local tmp_dir = os_getenv('TMP') or os_getenv('TEMP') or '.'
  local out_tmpfile, err_tmpfile

  if cmd.stdout == nil or cmd.stdout then
    out_tmpfile = path.random_file_name(tmp_dir .. '/out-XXXXXXXX.txt')
  end
  if cmd.stderr == nil or cmd.stderr then
    err_tmpfile = path.random_file_name(tmp_dir .. '/err-XXXXXXXX.txt')
  end

  local cmd_line = { cmd.name }
  if cmd.args then
    cmd_line[#cmd_line + 1] = cmd.args
  elseif cmd.arg_list then
    for i = 1, #cmd.arg_list do
      cmd_line[#cmd_line + 1] = cmd.arg_list[i]
    end
  end
  if out_tmpfile then
    cmd_line[#cmd_line + 1] = '>' .. out_tmpfile
  end

  if err_tmpfile then
    cmd_line[#cmd_line + 1] = '2>' .. err_tmpfile
  end

  cmd_line = tbl_concat(cmd_line, ' ')

  local ok = os_execute(cmd_line)
  if not ok then
    return false
  end

  local function read_file(file_path)
    if not file_path then
      return nil
    end

    local r = io.read_all(file_path)
    os_remove(file_path)
    if r then
      r = r:match('^(.-)%s*$')
    end
    if r and #r == 0 then
      return nil
    end
    return r
  end

  local out = read_file(out_tmpfile)
  local err = read_file(err_tmpfile)
  return true, out, err
end

return M

--- The command context.
-- Contains the customization options for a CLI application.
-- @table CommandContext
-- @tfield string name the command to execute.
-- @tfield[opt] table arg_list a list of command-line arguments.
-- @tfield[opt] string args a string containing the command-line arguments.
-- @tfield[opt] boolean stdout if `true` the command's output will be captured (default: `true`).
-- @tfield[opt] boolean stderr if `true` the command's error output will be captured (default: `true`).
