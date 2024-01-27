--- --- Provides extension functions to the Lua `os` module.
-- @module std.os

local M = setmetatable({}, {__index = os})

local iox = require 'std.iox'

local mth_random = math.random
local os_execute = os.execute
local os_getenv = os.getenv
local os_remove = os.remove
local str_char = string.char
local tbl_concat = table.concat

local _ENV = M

local IS_WINDOWS = package.config:sub(1, 1) == '\\'

function is_windows()
  return IS_WINDOWS
end

local function random_name(template)
  template = template or 'tmpXXXXXXXX'
  return (template:gsub('X', function()
    local rnd = mth_random(0, 61)
    if rnd < 10 then
      return str_char(rnd + 48)
    elseif rnd < 36 then
      return str_char(rnd + 55)
    end
    return str_char(rnd + 61)
  end))
end

--- Executes a given command
-- @tparam CommandContext cmd the command to execute
-- @treturn boolean `true` if the function succeeded, otherwise `false`.
-- @treturn CommandOutput the command output if the function succeeded, otherwise `nil`.
function execute(cmd)
  local tmp_dir = os_getenv('TMP') or os_getenv('TEMP') or '.'
  local out_tmpfile, err_tmpfile

  if cmd.stdout then
    out_tmpfile = random_name(tmp_dir .. '/out-XXXXXXXX.txt')
  end
  if cmd.stderr then
    err_tmpfile = random_name(tmp_dir .. '/err-XXXXXXXX.txt')
  end

  if IS_WINDOWS then
    cmd = cmd:gsub('/', '\\')
  end

  local cmd_line = { cmd.name }
  if cmd.args then
    cmd_line[#cmd_line + 1] = cmd.args
  elseif cmd.arglist then
    for i = 1, #cmd.arglist do
      cmd_line[#cmd_line + 1] = cmd.arglist[i]
    end
  end
  if out_tmpfile then
    cmd_line[#cmd_line + 1] = '>' .. out_tmpfile
  end

  if err_tmpfile then
    cmd_line[#cmd_line + 1] = '>' .. err_tmpfile
  end

  cmd_line = tbl_concat(cmd_line, ' ')

  local ok = os_execute(cmd_line)
  if not ok then
    return false
  end

  local r = {}
  if out_tmpfile then
    local out = iox.read_all(out_tmpfile)
    os_remove(out_tmpfile)
    if out then
      out = out:match('^(.-)%s*$')
    end
    r.stdout = out
  end

  if err_tmpfile then
    local err = iox.read_all(err_tmpfile)
    os_remove(err_tmpfile)
    if err then
      err = err:match('^(.-)%s*$')
      if #err == 0 then
        err = nil
      end
    end
    r.stderr = err
  end

  return true, r
end

return M

--- The command context.
-- Contains the customization options for a CLI application.
-- @table CommandContext
-- @tfield string name the command to execute.
-- @tfield[opt] table arglist a list of command-line arguments.
-- @tfield[opt] string args a string containing the command-line arguments.
-- @tfield[opt] boolean stdout if `true` the command's output will be captured.
-- @tfield[opt] boolean stderr if `true` the command's error outut will be captured.

--- The command output.
-- Contains the output of the command execution
-- @table CommandOutput
-- @tfield string stdout the capture command's output.
-- @tfield string stderr the capture command's error output.
