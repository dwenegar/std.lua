local M = {}

local stringx = require 'std.stringx'

local error = error
local ipairs = ipairs
local tonumber = tonumber

local math_type = math.type

local _ENV = M

local builtin_readers = {}
local custom_readers = {}
local cached_readers = {}

local function add_reader(t, type_names, requires_arg, read)
  local reader = {read = read, requires_arg = requires_arg, type = 'single'}
  for _, type_name in ipairs(type_names) do
    t[type_name] = reader
  end
end

add_reader(builtin_readers, {'string', 's'}, true, function(s)
  s = stringx.trim(s)
  local unquoted = s:match('^"(.*)"$')
  if not unquoted then
    unquoted = s:match("^'(.*)'$")
  end
  if not unquoted then
    unquoted = s
  end
  return stringx.unescape(unquoted)
end)

add_reader(builtin_readers, {'char', 'c'}, true, function(s)
  if #s == 1 then
    return s
  end
  return nil, ("invalid char: '%s'"):format(s)
end)

add_reader(builtin_readers, {'number', 'n','float', 'f'}, true, function(s)
  local v = tonumber(s)
  if v then
    return v
  end
  return nil, ("invalid number: '%s'"):format(s)
end)

add_reader(builtin_readers, {'integer', 'int', 'i'}, true, function(s)
  local v = tonumber(s)
  if v and math_type(v) == 'integer' then
    return v
  end
  return nil, ("invalid integer: '%s'"):format(s)
end)

add_reader(builtin_readers, {'flag', 'F'}, false, function()
  return true
end)

add_reader(builtin_readers, {'boolean', 'bool', 'b'}, true, function(s)
  local v = s:lower()
  if v == '1' or v == 't' or v == 'true' or v == 'yes' then return true end
  if v == '0' or v == 'f' or v == 'false' or v == 'no' then return false end
  return nil, ("invalid boolean: '%s'"):format(s)
end)

local function get_reader(type_name)
  return custom_readers[type_name] or builtin_readers[type_name]
end

local function check_type(type_name)
  if get_reader(type_name) then
    return type_name
  end
  return error('invalid type: ' .. type_name)
end

local function parse_tuple_type(type_name)
  local key_type, value_type = type_name:match('^(%w+)=(%w+)$')
  if key_type then
    key_type = check_type(key_type)
    value_type = check_type(value_type)
    return {key_type, value_type}
  end
end

--- parses a flag's type.
-- `t1=t2` defines a key-value pair
-- `{t1=t2}` defines a map
-- `[t]` defines a list
local function parse_type(type_name)
  local component_type = type_name:match('^{([^{}]+)}$')
  if not component_type then
    component_type = type_name:match('^%[([^%[%]]+)%]$')
    if component_type then
      local value_type = parse_tuple_type(component_type)
      if value_type then
        return 'tuple-list', value_type
      end
      value_type = check_type(component_type)
      return 'list', value_type
    end

    local value_type = parse_tuple_type(type_name)
    if value_type then
      return 'tuple', value_type
    end
    value_type = check_type(type_name)
    return 'single', value_type
  end

  local value_type = parse_tuple_type(component_type)
  if value_type then
    return 'map', value_type
  end
end

local function create_tuple_reader(value_type)
  local reader1 = create(value_type[1])
  if not reader1.requires_arg then
    return
  end
  local reader2 = create(value_type[2])
  if not reader2.requires_arg then
    return
  end
  return function(s)
    local k, v = s:match('^([^=]+)=([^=]+)$')
    if k then
      local err, v1, v2
      v1, err = reader1.read(k)
      if err then
        return nil, err
      end
      v2, err = reader2.read(v)
      if err then
        return nil, err
      end
      return {v1, v2}
    end
    return nil, ("not a tuple: '%s'"):format(s)
  end
end

local function create_map_reader(value_type)
  local read = create_tuple_reader(value_type)
  if read then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local kv, err = read(arg)
        if err then
          return nil, err
        end
        result[kv[1]] = kv[2]
      end
      return result
    end
  end
end

local function create_list_reader(value_type)
  local reader = create(value_type)
  if reader.requires_arg then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local v, err = reader.read(arg)
        if err then
          return nil, err
        end
        result[#result + 1] = v
      end
      return result
    end
  end
end

local function create_tuple_list_reader(value_type)
  local read = create_tuple_reader(value_type)
  if read then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local v, err = read(arg)
        if err then
          return nil, err
        end
        result[#result + 1] = v
      end
      return result
    end
  end
end

function create(type_name)
  if cached_readers[type_name] then
    return cached_readers[type_name]
  end

  local reader
  local reader_type, value_type = parse_type(type_name)
  if reader_type == 'single' then
    reader = get_reader(value_type)
  else
    local read
    if reader_type == 'list' then
      read = create_list_reader(value_type)
    elseif reader_type == 'tuple-list' then
      read = create_tuple_list_reader(value_type)
    elseif reader_type == 'map' then
      read = create_map_reader(value_type)
    elseif reader_type == 'tuple' then
      read = create_tuple_reader(value_type)
    end

    if read then
      reader = {read = read, requires_arg = true, type = reader_type}
    end
  end

  if not reader then
    error('invalid type: ' .. type_name)
  end

  cached_readers[type_name] = reader
  return reader
end

return M
