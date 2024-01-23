local M = {}

local array = require 'std.array'

local ipairs = ipairs
local select = select
local type = type

local math_min = math.min
local table_sort = table.sort

local _ENV = M

local INDENT = '  '

local function totable(x)
  return type(x) == 'table' and x or {x}
end

local function padding(size)
  return (' '):rep(size)
end

local function value_name(o)
  return o.value_name or '<value>'
end

local function key_name(o)
  return o.key_name or '<key>'
end

local function key_value_name(o)
  return ('%s=%s'):format(key_name(o), value_name(o))
end

local function arg_name(x)
  if x.arity == 2 then
    return key_value_name(x)
  elseif x.arity == 1 then
    return value_name(x)
  end
end

local function has_flags(flags, what)
  return array.any(flags, function(x)
    return not x.hidden and x.kind == what
  end)
end

local function sort_options(options)
  local function compare(lhs, rhs)
    if lhs and not rhs then
      return 1
    end
    if not lhs and rhs then
      return -1
    end
    if lhs == rhs then
      return 0
    end
    if lhs < rhs then
      return -1
    end
    return 1
  end

  table_sort(options, function(lhs, rhs)
    local cmp = compare(lhs.long, rhs.long)
    if cmp == 0 then
      cmp = compare(lhs.short, rhs.short)
    end
    return cmp < 0
  end)
end

local function sort_commands(commands)
  table_sort(commands, function(lhs, rhs)
    return lhs.name < rhs.name
  end)
end

local function buf_newline(buf)
  buf[#buf + 1] = '\n'
end

local function buf_append(buf, ...)
  local len = 0
  for i = 1, select('#', ...) do
    local s = select(i, ...)
    buf[#buf + 1] = s
    len = len + #s
  end
  return len
end

local function buf_append_line(buf, ...)
  buf_append(buf, ...)
  buf_newline(buf)
end

local function buf_header(buf, text)
  buf_newline(buf)
  buf_append_line(buf, text)
end

local function buf_append_name(buf, cmd)
  if cmd.parent then
    buf_append_name(buf, cmd.parent)
    buf_append(buf, ' ', cmd.name)
  else
    buf_append(buf, cmd.name)
  end
end

local function buf_append_usage(buf, cmd)
  buf_append_line(buf, "Usage:")
  if has_flags(cmd, 'option') then
    buf_append(buf, INDENT)
    buf_append_name(buf, cmd)
    buf_append(buf, ' [options]')
    buf_newline(buf)
  end
  if has_flags(cmd, 'command') then
    buf_append(buf, INDENT)
    buf_append_name(buf, cmd)
    buf_append(buf, ' [command]')
    buf_newline(buf)
  end
end

local function buf_append_aliases(buf, cmd)
  if cmd.aliases then
    local aliases = totable(cmd.aliases)
    if #aliases == 0 then
      return
    end

    buf_header(buf, "Aliases:")
    buf_append(buf, INDENT, cmd.name, ', ')
    table_sort(aliases)
    for i, alias in ipairs(aliases) do
      buf_append(buf, alias)
      if i < #aliases then
        buf_append(buf, ', ')
      end
    end
    buf_newline(buf)
  end
end

local function buf_append_examples(buf, cmd)
  if cmd.examples then
    local examples = totable(cmd.examples)
    if #examples == 0 then
      return
    end

    buf_header(buf, "Examples:")
    for _, example in ipairs(examples) do
      buf_append_line(buf, INDENT, example)
    end
  end
end

local function buf_append_summary(buf, cmd)
  if cmd.summary and #cmd.summary > 0 then
    buf_append_line(buf, cmd.summary)
    buf_newline(buf)
  end
end

local function buf_append_footer(buf, cmd)
  if cmd.footer then
    buf_newline(buf)
    buf_append_line(buf, cmd.footer)
  end
end

local function buf_append_commands(buf, cmd)
  local commands = array.filter(cmd, function(x)
    return not x.hidden and x.kind == 'command'
  end)
  if #commands > 0 then
    buf_header(buf, "Available Commands:")
    sort_commands(commands)
    local max_len = 0
    for _, c in ipairs(commands) do
      if #c.name > max_len then
        max_len = #c.name
      end
    end

    for _, c in ipairs(commands) do
      buf_append(buf, INDENT, c.name)
      if c.description then
        buf_append(buf, padding(max_len - #c.name + 2), c.description)
      end
      buf_newline(buf)
    end
  end
end

local function buf_append_options(buf, cmd)

  local function _buf_append_options(label, options)
    buf_header(buf, label)

    sort_options(options)
    local arg_names = {}
    local short_max_len = 0
    for i, o in ipairs(options) do
      if o.short then
        short_max_len = 2
      end
      arg_names[i] = arg_name(o)
    end
    local max_len = 0
    for i, o in ipairs(options) do
      local len
      if o.short then
        if o.long then
          -- "-S" + ", " + "--LONG"
          len = 6 + #o.long
        else
          -- "-S"
          len = 2
        end
      elseif o.long then
        -- "--LONG"
        len = short_max_len + 2 + #o.long
      end
      local name = arg_names[i]
      if name then
        if o.long then
          len = len + 1
        end
        len = len + #name
      end
      if len > max_len then
        max_len = len
      end
    end

    for i, o in ipairs(options) do
      local name = arg_names[i]

      local len = 0
      local function _append(...)
        len = len + buf_append(buf, ...)
      end

      if o.short then
        _append(INDENT, '-', o.short)
        if o.long then
          _append(padding(short_max_len - #o.short - 1), ', --', o.long)
          if name then
            if o.parser.type == 'single' then
              _append('=')
            elseif o.parser.type == 'tuple' then
              _append(':')
            end
            _append(name)
          end
        elseif name then
          _append(name)
        end
      elseif o.long then
        _append(INDENT)
        if short_max_len > 0 then
          _append(padding(short_max_len + 2))
        end
        _append('--', o.long)
        if name then
          if o.parser.type == 'single' then
            _append('=')
          elseif o.parser.type == 'tuple' then
            _append(':')
          end
          _append(name)
        end
      end
      _append(padding(2 + max_len - len))
      if o.description then
        _append(INDENT, o.description)
      end
      buf_newline(buf)
    end
  end

  local c, global_options = cmd, {}
  while c do
    array.insert_all_if(c, global_options, function(x)
      return x.kind == 'option' and not x.hidden and x.global
    end)
    c = c.parent
  end
  if #global_options > 0 then
    _buf_append_options("Global Options:", global_options)
  end

  local options = array.filter(cmd, function(x)
    return x.kind == 'option' and not x.hidden and not x.global
  end)
  if #options > 0 then
    _buf_append_options("Options:", options)
  end
end

function format_help(cmd)
  local buf = {}
  buf_append_summary(buf, cmd)
  buf_append_usage(buf, cmd)
  buf_append_aliases(buf, cmd)
  buf_append_examples(buf, cmd)
  buf_append_commands(buf, cmd)
  buf_append_options(buf, cmd)
  buf_append_footer(buf, cmd)
  buf_newline(buf)
  return buf
end

function format_usage(cmd)
  local buf = {}
  buf_append_usage(buf, cmd)
  buf_append_aliases(buf, cmd)
  buf_append_examples(buf, cmd)
  buf_append_commands(buf, cmd)
  buf_append_options(buf, cmd)
  buf_append_footer(buf, cmd)
  buf_newline(buf)
  return buf
end

function format_version(cmd)
  local buf = {}
  if cmd.version then
    if cmd.description then
      buf_append(buf, cmd.description)
    else
      buf_append(buf, cmd.name)
    end
    buf_append_line(buf, ' version ', cmd.version)
    buf_newline(buf)
  end
  return buf
end


function find_suggestions(cmd, arg)

  local cache = {}
  local function chars(s)
    if not cache[s] then
      local r = {}
      for c in s:gmatch('.') do
        r[#r + 1] = c
      end
      cache[s] = r
    end
    return cache[s]
  end

  local function distance(s, t)
    if #s == 0 then
      return #t
    end
    if #t == 0 then
      return #s
    end
    s, t = chars(s), chars(t)
    local v0, v1 = {}, {}
    for i = 0, #t do
      v0[i] = i
    end
    for i = 1, #s do
      v1[0] = i
      for j = 1, #t do
        local dc = v0[j] + 1
        local ic = v1[j - 1] + 1
        local sc = v0[j - 1] + (s[i] == t[j] and 0 or 1)
        v1[j] = math_min(dc, math_min(ic, sc))
      end
      v0, v1 = v1, v0
    end
    return v0[#t]
  end

  local distance_threshold = cmd.distance_threshold
  if not distance_threshold or distance_threshold < 1 then
    distance_threshold = 2
  end

  local suggestions = {}
  for _, x in ipairs(cmd) do
    if x.kind == 'command' and not x.hidden then
      local suggested_by_distance = distance(arg, x.name) < distance_threshold
      local suggested_by_prefix = x.name:find(arg) == 1
      if suggested_by_distance or suggested_by_prefix then
        suggestions[#suggestions + 1] = x.name
      end
    end
  end
  return suggestions
end

return M
