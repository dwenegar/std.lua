local M = {}

local array = require 'std.array'
local help = require 'std.cli.help'
local flag = require 'std.cli.flag'
local parser = require 'std.cli.parser'

local ipairs = ipairs
local select = select

local _ENV = M

local function print_error(cmd, ...)
  if select('#', ...) > 0 then
    cmd.error_writer(...)
  end
  cmd.error_writer('\n')
end

local function print_errorf(cmd, fmt, ...)
  cmd.error_writer(fmt:format(...))
  cmd.error_writer('\n')
end

local function buf_write(buf, write)
  for _, x in ipairs(buf) do
    write(x)
  end
end

local function print_version(cmd)
  local buf = help.format_version(cmd)
  buf_write(buf, cmd.writer)
end

local function print_usage(cmd)
  local buf = help.format_usage(cmd)
  buf_write(buf, cmd.error_writer)
end

local function print_help(cmd)
  local buf = help.format_help(cmd)
  buf_write(buf, cmd.writer)
end

local function setup_help_flags(cmd)
  if cmd.hide_help then
    return
  end

  local has_help_option, has_child_commands, has_help_command
  for _, x in ipairs(cmd) do
    if x.kind == 'option' then
      if x.long == 'help' or x.short == 'h' then
        has_help_option = true
      end
    elseif x.kind == 'command' then
      has_child_commands = true
      if x.name == 'help' then
        has_help_command = true
      end
    end
  end

  if not has_help_option then
    cmd[#cmd + 1] = flag.option {
      long = 'help',
      short = 'h',
      description = "Help for " .. cmd.path,
      action = function()
        print_help(cmd)
        cmd.exit(0)
      end
    }
  end

  if has_child_commands and not has_help_command then
    local help_cmd = flag.command {
      name = 'help',
      summary = "Help provides help for any command in the application",
      description = 'Help for any command',
      flag.argument {name = 'command'},
      action = function(_, ctx)
        if not ctx.command then
          print_help(cmd)
          return cmd.exit(0)
        else
          local c = ctx.command and array.find(cmd, function(x)
            return x.kind == 'command' and x.name == ctx.command
          end)
          if c then
            print_help(c)
            cmd.exit(0)
          else
            print_errorf(cmd, "Unknown help topic '%s'\n", ctx.command)
            print_usage(cmd)
            cmd.exit(1)
          end
        end
      end
    }

    set_parent(help_cmd, cmd, true)
    cmd[#cmd + 1] = help_cmd
  end
end

local function setup_version_flags(cmd)
  if not cmd.version or cmd.hide_version then
    return
  end

  local has_version_option, has_version_command
  for _, x in ipairs(cmd) do
    if x.kind == 'option' then
      if x.long == 'version' or x.short == 'V' then
        has_version_option = true
      end
    elseif x.kind == 'command' then
      if x.name == 'version' then
        has_version_command = true
      end
    end
  end

  local desc = (cmd.kind == 'command' and cmd.parent)
    and "Show the command name and version"
    or "Show the program name and version"

  if not has_version_option then
    cmd[#cmd + 1] = flag.option {
      long = 'version',
      short = 'V',
      description = desc,
      action = function()
        print_version(cmd)
        cmd.exit(0)
      end
    }
  end

  if not has_version_command then
    local version_cmd = flag.command {
      name = 'version',
      description = desc,
      action = function()
        print_version(cmd)
      end
    }
    cmd[#cmd + 1] = version_cmd
  end
end

function set_parent(cmd, parent, is_leaf)
  cmd.parent = parent
  cmd.path = cmd.name
  if parent then
    cmd.path = ('%s %s'):format(cmd.parent.path, cmd.name)
    cmd.error_writer = parent.error_writer
    cmd.disable_suggestions = parent.disable_suggestions
    cmd.exit = parent.exit
    cmd.hide_help = parent.hide_help
    cmd.hide_version = parent.hide_version
    cmd.writer = parent.writer
  end

  for _, x in ipairs(cmd) do
    if x.kind == 'command' then
      set_parent(x, cmd)
    end
  end

  if not is_leaf then
    setup_version_flags(cmd)
    setup_help_flags(cmd)
  end
end

local function exit(cmd, err)
  if cmd.exit then
    cmd.exit(err and 1 or 0)
  end

  return cmd, err
end

function run(cmd, args)
  set_parent(cmd)
  local target_cmd, ctx, err = parser.parse(cmd, args or {})
  if err then
    if not cmd.no_errors and not target_cmd.no_errors then
      print_error(target_cmd, "Error: ", err)
      local has_help_option = not not array.find(target_cmd, function(x)
        return x.kind == 'option' and (x.long == 'help' or x.short == 'h')
      end)
      local has_help_command = not not array.find(target_cmd, function(x)
        return x.kind == 'command' and x.name == 'help'
      end)
      if has_help_option then
        print_errorf(target_cmd, "Run '%s --help' for usage", target_cmd.path)
      elseif has_help_command then
        print_errorf(target_cmd, "Run '%s help' for usage", target_cmd.path)
      end
      print_error(target_cmd)
    end

    return exit(target_cmd, err)
  end

  if target_cmd.validate then
    err = target_cmd.validate(target_cmd, ctx)
  end

  if not err and target_cmd.action then
    err = target_cmd.action(target_cmd, ctx)
  end

  if err then
    if not cmd.no_errors and not target_cmd.no_errors then
      print_error(target_cmd, "Error: ", err, '\n')
    end

    if not cmd.no_usage and not target_cmd.no_usage then
      print_usage(target_cmd)
    end
  end

  return exit(target_cmd, err)
end

return M
