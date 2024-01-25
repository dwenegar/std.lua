--- Provides functions to pretty-print tables and arrays.
-- @module std.pretty
local M = {}

local checks = require 'std.checks'
local hash = require 'std.hash'
local shapes = require 'std.shapes'

local next = next
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring

local tbl_sort = table.sort
local tbl_concat = table.concat
local tbl_insert = table.insert

local _ENV = M

local Keywords = {
  ['and'] = true, ['break'] = true,  ['do'] = true,
  ['else'] = true, ['elseif'] = true, ['end'] = true,
  ['false'] = true, ['for'] = true, ['function'] = true,
  ['if'] = true, ['in'] = true,  ['local'] = true, ['nil'] = true,
  ['not'] = true, ['or'] = true, ['repeat'] = true,
  ['return'] = true, ['then'] = true, ['true'] = true,
  ['until'] = true,  ['while'] = true
}

local function is_simple_name(s)
  return s:find('^[%a_][%w_]*$')
end

local function is_identifier(s)
  return type(s) == 'string' and s:find('^[%a_][%w_]*$') and not Keywords[s]
end

local TypeSortOrder = {
  ['number'] = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function key_cmp(a,b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then
    return TypeSortOrder[ta] < TypeSortOrder[tb]
  end
  if ta == 'number' then
    return a < b
  end
  if ta ~= 'string' then
    return true
  end
  if is_simple_name(a) then
    if is_simple_name(b) then
      return a < b
    end
    return true
  elseif is_simple_name(b) then
    return false
  end
  return a < b
end

local function get_sorted_keys(t)
  local r = {}
  for k in pairs(t) do
    r[#r + 1] = k
  end
  tbl_sort(r, key_cmp)
  return r
end

local function keys(t, sorted)
  if sorted then
    local i, tmp = 0, get_sorted_keys(t)
    return function()
      i = i + 1
      return tmp[i]
    end
  end

  local k
  return function()
    k = next(t, k)
    return k
  end
end

local EscapeSequences = {
  ['\a']='\\a',
  ['\b']='\\b',
  ['\f']='\\f',
  ['\n']='\\n',
  ['\r']='\\r',
  ['\t']='\\t',
  ['\v']='\\v',
  ['\\']='\\\\',
  ['\'']='\\\'',
}

local function escape(s)
  return s:gsub('.', EscapeSequences)
end

local function quote(s)
  return ("'%s'"):format(s)
end

local function to_set(x)
  if type(x) == 'table' then
    local r = {}
    for _, v in ipairs(x) do
      r[v] = true
    end
    return r
  end
end

local noop = function() end

local DefaultOptions = {
  comma = true,
  indent_size = 2,
  max_depth = 10,
  minimize = false,
  number_format = '%.16g',
  indent_style = 'space',
  smart_keys = true,
  sort_keys = true,
}

local OptionsShape = shapes.shape({
  indent_style = shapes.one_of('tab', 'space'),
  indent_size = shapes.min(0),
  sort_keys = shapes.boolean,
  minimize = shapes.boolean,
  max_depth = shapes.min(0),
  include_keys = shapes.array_of(shapes.string),
  exclude_keys = shapes.array_of(shapes.string),
  number_format = shapes.string
}, {mode = 'dictionary', exact = true})

local function merge_options(options, defaults)
  if not options then
    return defaults
  end
  local r = {}
  for k, v in pairs(options) do
    r[k] = v
  end
  for k, v in pairs(defaults) do
    if options[k] == nil then
      r[k] = v
    else
      r[k] = options[k]
    end
  end
  return r
end

--- Pretty-print a given table using the specified options.
-- @tparam table t the table to pretty print
-- @tparam[opt] PrettifyOptions opts the options
-- @treturn string a pretty-printed string representation of `t`
function prettify_table(t, opts)
  checks.check_types('table', '?table')

  opts = merge_options(opts, DefaultOptions)
  local err = OptionsShape(opts)
  if err then
    checks.arg_error(2, tostring(err))
  end

  local refs, ref_positions = {}, {}
  local function add_ref(x)
    if not refs[x] then
      refs[x] = '<' .. hash.hash(x) .. '>'
    end
  end

  -- invoked after a reference has been inserted at the specified position.
  local function update_ref_positions(pos)
    for k, ref_pos in pairs(ref_positions) do
      if ref_pos > pos then
        ref_positions[k] = ref_pos + 1
      end
    end
  end

  local comma = opts.comma
  local indent_size = opts.indent_size
  local limit = opts.limit
  local max_depth = opts.max_depth
  local minimize = opts.minimize
  local number_format = opts.number_format
  local smart_keys = opts.smart_keys
  local sort_keys = opts.sort_keys
  local indent_with_tabs = opts.indent_style == 'tab'

  local include_keys = to_set(opts.include_keys)
  local exclude_keys = to_set(opts.exclude_keys)
  local filter = opts.filter
  local function is_key_included(x)
    if filter then
      return filter(x)
    elseif include_keys then
      return include_keys[x]
    elseif exclude_keys then
      return not exclude_keys[x]
    end
    return true
  end

  local buf = {}

  local level, indent_cache = 0, {}
  local add_indent = (minimize or indent_size <= 0) and noop or function()
    local indent = indent_cache[level]
    if not indent then
      if level == 1 then
        indent = indent_with_tabs and '\t' or (' '):rep(indent_size)
      else
        indent = indent_cache[1]:rep(level)
      end
      indent_cache[level] = indent
    end
    buf[#buf + 1] = indent
  end

  local add_comma = not comma and noop or function()
    buf[#buf + 1] = ','
  end

  local add_nl = minimize and noop or function()
    buf[#buf + 1] = '\n'
  end

  local add_value -- forward declaration

  local function add_key(x)
    if smart_keys and is_identifier(x) then
      buf[#buf + 1] = x
      buf[#buf + 1] = minimize and '=' or ' = '
    else
      buf[#buf + 1] = '['
      add_value(x)
      buf[#buf + 1] = minimize and ']=' or '] = '
    end
  end

  local function add_table(x)
    if not refs[x] then
      ref_positions[x] = #buf + 1
    end

    if refs[x] then
      buf[#buf + 1] = refs[x]
      return
    end

    if not next(x) then
      buf[#buf + 1] = '{}'
      return
    end

    if level >= max_depth then
      buf[#buf + 1] = '{...}'
      return
    end

    buf[#buf + 1] = '{'
    level = level + 1

    local n = 1
    for k in keys(x, sort_keys) do
      if is_key_included(k) then
        add_nl()
        add_indent()

        if limit and limit < n then
          buf[#buf + 1] = '...'
          break
        end

        add_key(k)
        add_value(x[k])
        add_comma()
        n = n + 1
      end
    end

    if buf[#buf] == ',' then
      buf[#buf] = nil
    end

    add_nl()

    level = level - 1
    add_indent()
    buf[#buf + 1] = '}'
  end

   add_value = function(x)
    if x == nil then
      buf[#buf + 1] = 'nil'
      return
    end

    local tv = type(x)
    if tv == 'string' then
      buf[#buf + 1] = quote(escape(x))
    elseif tv == 'number' then
      buf[#buf + 1] = number_format:format(x)
    elseif tv == 'boolean' then
      buf[#buf + 1] = tostring(x)
    elseif tv == 'table' then
      local pos = ref_positions[x]
      if pos then
        add_ref(x)
        tbl_insert(buf, pos, refs[x])
        ref_positions[x] = nil
        update_ref_positions(pos)
      end
      add_table(x)
    else
      buf[#buf + 1] = '<'
      buf[#buf + 1] = tostring(x)
      buf[#buf + 1] = '>'
    end
  end

  add_value(t)
  return tbl_concat(buf)
end

--- Pretty-print a given array using the specified options.
-- @tparam table a the array to pretty print
-- @tparam[opt] PrettifyOptions opts the options
-- @treturn string a pretty-printed string representation of `a`
function prettify_array(a, opts)
  checks.check_types('table', '?table')

  opts = merge_options(opts, DefaultOptions)
  local err = OptionsShape(opts)
  if err then
    checks.arg_error(2, tostring(err))
  end

  local refs, ref_positions = {}, {}
  local function add_ref(x)
    if not refs[x] then
      refs[x] = '<' .. hash.hash(x) .. '>'
    end
  end

    -- invoked after a reference has been inserted at the specified position.
    local function update_ref_positions(pos)
      for k, ref_pos in pairs(ref_positions) do
        if ref_pos > pos then
          ref_positions[k] = ref_pos + 1
        end
      end
    end

    local limit = opts.limit
    local max_depth = opts.max_depth
    local minimize = opts.minimize
    local number_format = opts.number_format

    local buf = {}

    local level = 0

    local add_value -- forward declaration

    local function add_array(x)
      if not refs[x] then
        ref_positions[x] = #buf + 1
      end

      if refs[x] then
        buf[#buf + 1] = refs[x]
        return
      end

      if level >= max_depth then
        buf[#buf + 1] = minimize and '{...}' or '{ ... }'
        return
      end

      level = level + 1
      buf[#buf + 1] = minimize and '{' or '{ '
      for i, v in ipairs(x) do
        if limit and limit < i then
          buf[#buf + 1] = '...'
          break
        end
        add_value(v)
        buf[#buf + 1] = minimize and ',' or ', '
      end

      if buf[#buf] == ',' or buf[#buf] == ', ' then
        buf[#buf] = nil
      end

      buf[#buf + 1] = minimize and '}' or ' }'
      level = level - 1
    end

    local function add_table(x)
      if refs[x] then
        buf[#buf + 1] = refs[x]
        return
      end
      if #x == 0 then
        add_ref(x)
        buf[#buf + 1] = refs[x]
      else
        add_array(x)
      end
    end

    add_value = function(x)
      if x == nil then
        buf[#buf + 1] = 'nil'
        return
      end

      local tv = type(x)
      if tv == 'string' then
        buf[#buf + 1] = quote(escape(x))
      elseif tv == 'number' then
        buf[#buf + 1] = number_format:format(x)
      elseif tv == 'boolean' then
        buf[#buf + 1] = tostring(x)
      elseif tv == 'table' then
        local pos = ref_positions[x]
        if pos then
          add_ref(x)
          tbl_insert(buf, pos, refs[x])
          ref_positions[x] = nil
          update_ref_positions(pos)
        end
        add_table(x)
      else
        buf[#buf + 1] = '<'
        buf[#buf + 1] = tostring(x)
        buf[#buf + 1] = '>'
      end
    end

    add_value(a)
    return tbl_concat(buf)
end

--- Options for the `to_string` function.
-- @table PrettifyOptions
-- @tfield boolean indent_style set to `"tab"` or `"space"` to use hard tabs or soft tabs respectively.
-- @tfield integer indent_size the size (in number of spaces) of an indent; ignored if `indent_style` is `true`.
-- @tfield boolean sort_keys whether to sort the table keys or not
-- @tfield boolean smart_keys
-- @tfield boolean minimize
-- @tfield integer max_depth
-- @tfield table include_keys a table of keys to include
-- @tfield table exclude_keys a table of keys to exclude
-- @tfield string number_format the format string to use when formatting numbers (default: '%.16g')

-- @tfield[opt=no limit] integer limit if `minimize` is `true`, it specifies the maximum length of the returned string,
-- otherwise it indicates the maximum number of newlines in the returned string.

return M
