--- Runtime checks for Lua tables.
--
-- @module std.shapes
local M = {}

local checks = require 'std.checks'
local stringx = require 'std.stringx'
local tablex = require 'std.tablex'

local error = error
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local rawget = rawget
local setmetatable = setmetatable
local tostring = tostring
local type = type

local math_type = math.type
local tbl_concat = table.concat
local tbl_pack = table.pack

local _ENV = M

local indent = ''
local push_indent, pop_indent
do
  local level = 1
  local stack = {''}
  function push_indent()
    level = level + 1
    if not stack[level] then
      stack[level] = stack[level - 1] .. '  '
    end
    indent = stack[level]
  end

  function pop_indent()
    if level == 1 then
      error("stack is empty")
    end
    level = level - 1
    indent = stack[level]
  end
end

local function format_key(value)
  if type(value) == 'string' then
    -- simple strings are returned as-is (for example: aa, aa_bb)
    if value:match('^[%a_][%w_]*$') then
      return value
    end
  elseif math_type(value) == 'integer' then
    return ("[%d]"):format(value)
  end
  return ("[%s]"):format(stringx.smart_quotes(value))
end

local function format_value(value)
  local value_type = type(value)
  if value_type == 'string' then
    return stringx.smart_quotes(value)
  end
  return tostring(value)
end

local function format_values(values, sep, last_sep)
  if #values == 0 then
    return ''
  elseif #values == 1 then
    return format_value(values[1])
  end
  sep = sep or ', '
  last_sep = last_sep or sep
  local b = {}
  b[#b + 1] = format_value(values[1])
  for i = 2, #values - 1 do
    b[#b + 1] = sep
    b[#b + 1] = format_value(values[i])
  end
  if #values > 1 then
    b[#b + 1] = last_sep
    b[#b + 1] = format_value(values[#values])
  end
  return tbl_concat(b)
end

local error_mt = {
  __tostring = function(self)
    local b = {}
    local function append(err, parent)
      if type(err) == 'string' then
        b[#b + 1] = parent and ': ' or nil
        b[#b + 1] = err
      elseif err.type == 'field_error' then
        local key = format_key(err.key)
        if not parent or parent.type ~= 'field_error' then
          b[#b + 1] = 'invalid value '
        elseif not key:match('^%[') then
          b[#b + 1] = '.'
        end
        b[#b + 1] = key
        if err.error then
          append(err.error, err)
        end
      elseif err.type == 'aggregate_error' and err.errors then
        b[#b + 1] = parent and ':\n' or nil
        for i, x in ipairs(err.errors) do
          b[#b + 1] = indent
          push_indent()
          append(x, err)
          pop_indent()
          b[#b + 1] = i < #err.errors and '\n' or nil
        end
      end
    end
    append(self)
    return tbl_concat(b)
  end
}

local function aggregate_error(errors)
  if not errors then
    return nil
  elseif #errors == 1 then
    return errors[1]
  end
  return setmetatable({type = 'aggregate_error', errors = errors}, error_mt)
end

local function field_error(key, err)
  return setmetatable({type = 'field_error', key = key, error = err}, error_mt)
end

local function type_error(expected, actual)
  return ("expected %s, got %s"):format(expected, actual)
end

local shape_mt = {
  __call = function(self, value)
    checks.check_types('shape', '?any')
    return self:call(value)
  end,
  __tostring = function(self)
    return self.optional and self:tostring() or 'required ' .. self:tostring()
  end,
  __add = function(l, r)
    if l.name == 'one_of' then
      l.shapes[#l.shapes + 1] = r
      return l
    end
    return one_of(l, r)
  end,
  __mul = function(l, r)
    if l.name == 'all_of' then
      l.shapes[#l.shapes + 1] = r
      return l
    end
    return all_of(l, r)
  end,
  __unm = function(self)
    return negate(self)
  end
}

local function is_shape(x)
  return getmetatable(x) == shape_mt
end

checks.register_type('shape', is_shape)

--[[
  Structure of a shape:

  shape = {
    id = shape identifier
    name = shape name
    describe = a function returning the shape's string representation
    validate = a function implementing the shape's validation logic
    call = the function invoked by the __call metamethod
    tostring = the function invoked by the __tostring metamethod (forward to describe)
    required = the required version of the shape
  }
]]
local function shape_init(name, base, validate, describe, required)
  local shape = base
  shape.name = name
  shape.describe = describe
  shape.validate = validate
  shape.tostring = describe
  shape.optional = not required
  return setmetatable(shape, shape_mt)
end

local function create_shape(name, base, validate, describe, required_only)
  if required_only then
    local shape = shape_init(name, base, validate, describe, true)
    shape.call = function(self, value)
      if value ~= nil then
        return self:validate(value)
      end
      return ("missing %s"):format(self)
    end
    return shape
  end

  local shape = shape_init(name, tablex.clone(base), validate, describe)
  shape.call = function(self, value)
    if value ~= nil then
      return self:validate(value)
    end
  end
  shape.required = shape_init(name, base, validate, describe, true)
  shape.required.call = function(self, value)
    if value ~= nil then
      return self:validate(value)
    end
    return ("missing %s"):format(self)
  end
  return shape
end

--- Creates a shape accepting a value that _does not_ match a given shape.
-- @tparam shape shape the shape to test for.
-- @treturn shape a new shape.
function negate(shape)
  checks.check_types('shape')
  local base = {shape = shape}
  return create_shape('negate', base, function(self, value)
    local err = self.shape(value)
    if not err then
      return type_error(self, format_value(value))
    end
  end, function(self)
    return ('not (%s)'):format(self.shape)
  end)
end

--- Creates a shape accepting a value of a given type.
-- @tparam string expected the name of the type to test for.
-- @treturn shape a new shape.
function is_a(expected)
  local base = {expected = expected}
  return create_shape(expected, base, function(self, value)
    local value_type = type(value)
    if value_type == self.expected then
      return
    end
    local mt = getmetatable(value)
    if mt then
      value_type = rawget(mt, '__name')
      if value_type == self.expected then
        return
      end
      value_type = rawget(mt, '__type')
      if value_type == self.expected then
        return
      end
    end
    return type_error(self, type(value))
  end, function(self)
    return self.expected
  end)
end

local function validate_array_of(self, value)
  if type(value) ~= 'table' then
    return type_error(self, type(value))
  end

  local errors
  local function append_error(err)
    errors = errors or {}
    errors[#errors + 1] = err
  end

  local fail_fast = self.fail_fast

  if self.length and #value ~= self.length then
    local err = ("expected array length equal to %d, got %d"):format(self.length, #value)
    if not fail_fast then
      return err
    end
    append_error(err)
  end

  if self.min_length and #value < self.min_length then
    local err = ("expected array length greater or equal to than %d, got %d"):format(self.min_length, #value)
    if not fail_fast then
      return err
    end
    append_error(err)
  end

  if self.max_length and #value > self.max_length then
    local err = ("expected array length less or equal to than %d, got %d"):format(self.max_length, #value)
    if not fail_fast then
      return err
    end
    append_error(err)
  end

  local expected = self.expected
  for i, v in ipairs(value) do
    local err = expected:validate(v, value, i)
    if err then
      err = field_error(i, err);
      if fail_fast then
        return err
      end
      append_error(err)
    end
  end

  return aggregate_error(errors)
end

--- Create a shape accepting an array of value of a given type.
-- @tparam shape value a shape accepting the base type of the array.
-- @tparam table options a table containing the options of the array shape; valid options are:
--
-- - `min_length`: specifies the minimum length of the array;
-- - `max_length`: specifies the maximum length of the array;
-- - `length`: specifies the length of the array (takes the precedence on `min_length` and `max_length`);
-- - `fail_fast`: specifies if checking should stop at the first error or not.
--
-- @treturn shape a new shape.
function array_of(value, options)
  checks.check_types('shape', '?table')
  local base = {expected = value}
  if options then
    base.min_length = options.min_length
    base.max_length = options.max_length
    base.length = options.length
    base.fail_fast = options.fail_fast
  end
  return create_shape('array_of', base, validate_array_of, function(self)
    return ('array of (%s)'):format(self.expected)
  end)
end

-- used to keep track of nested shapes (used by ref_to)
local shape_stack = {}
local function push_shape(shape)
  shape_stack[#shape_stack + 1] = shape
end

local function pop_shape()
  if #shape_stack == 0 then
    error("invalid operation (stack is empty)")
  end
  shape_stack[#shape_stack] = nil
end

--- Creates a shape referencing another shape identified by a given path.
-- @tparam string path the path of the referenced shape.
-- @treturn shape a new shape.
-- @usage
-- local test = shapes.shape {
--   x = string.int,
--   y = shape.ref_to '/' -- references test
-- }
function ref_to(path)
  checks.check_types('string')
  if #path == 0 then
    checks.arg_error(1, 'invalid path')
  end
  local base = {path = path}
  return create_shape('ref', base, function(self, value)
    if not self.expected then
      local index = not not self.path:match('^/') and 1 or #shape_stack
      local expected = shape_stack[index]
      for x in self.path:gmatch('[^/]+') do
        if x == '..' then
          index = index - 1
          if index == 0 then
            return ("invalid path %s"):format(self.path)
          end
          expected = shape_stack[index]
        else
          expected = rawget(expected.shapes, x)
          index = index + 1
        end
        if not is_shape(expected) then
          return ("path %s does not point to a valid shape"):format(self.path)
        end
      end
      self.expected = expected
    end
    return self.expected(value)
  end, function(self)
    return ("reference to %s"):format(self.path)
  end)
end

function validate_shape(self, value)
  if type(value) ~= 'table' then
    return type_error(self, type(value))
  end

  local errors
  local function append_error(err)
    errors = errors or {}
    errors[#errors + 1] = err
  end

  local exact = self.exact
  local dict_mode = self.mode ~= 'array'
  local array_mode = self.mode ~= 'dictionary'
  local fail_fast = self.fail_fast
  local shapes = self.shapes

  local err

  if exact then
    for key in pairs(value) do
      if math_type(key) == 'integer' and array_mode or type(key) == 'string' and dict_mode then
        if shapes[key] == nil then
          err = ("unexpected key %s"):format(format_value(key))
          if fail_fast then
            return err
          end
          append_error(err)
        end

        if value[key] == nil and not shapes[key].optional then
          err = ("missing key %s"):format(format_value(key))
          if fail_fast then
            return err
          end
          append_error(err)
        end
      end
    end
  end

  push_shape(self)
  for key, shape in pairs(shapes) do
    err = shape(value[key])
    if err then
      err = field_error(key, err)
      if fail_fast then
        return err
      end
      append_error(err)
    end
  end
  pop_shape()
  return aggregate_error(errors)
end

local function describe_shape(self)
  local b = {'{'}
  local function append(shape)
    push_indent()
    for k, v in pairs(shape.shapes) do
      b[#b + 1] = ('%s%s = %s'):format(indent, format_key(k), format_value(v))
    end
    pop_indent()
    b[#b + 1] = indent .. '}'
  end
  append(self)
  return tbl_concat(b, '\n')
end

--- Creates a shape that matches a given table structure.
-- @tparam table shapes the table of shapes to test for.
-- @tparam[opt] table options a table containing the options of the array shape; valid options are:
-- - `exact`: specifies if the tested table must **exactly** match the shape.
-- - `mode`: specifies how the table should be checked; valid modes are:
--    - `array`: only the array part will be checked.
--    - `dictionary`: only the dictionary part will be checked.
--    - `nil` or unset: whole table to be checked.
-- - `fail_fast`: specifies if checking should stop at the first error or not.
-- @treturn shape a new shape.
function shape(shapes, options)
  checks.check_types('table', '?table')
  local err

  local prop_names = {}
  for k in pairs(shapes) do
    if type(k) ~= 'string' and math_type(k) ~= 'integer' then
      err = ("invalid key: string or integer expected, got %s"):format(type(k))
      checks.arg_error(1, err, 2)
    end
    prop_names[#prop_names + 1] = k
  end

  local function copy(src, dst)
    for k, v in pairs(src) do
      if is_shape(v) then
        dst[k] = v
      elseif type(v) == 'table' then
        dst[k] = copy(v, {})
      else
        dst[k] = v
      end
    end
    return dst
  end

  shapes = copy(shapes, {})
  for k, v in pairs(shapes) do
    if not is_shape(v) then
      shapes[k] = equal(v)
    end
  end

  local base = {shapes = shapes, prop_names = prop_names}
  if options then
    base.fail_fast = options.fail_fast
    base.exact = options.exact
    base.mode = options.mode
  end

  return create_shape('shape', base, validate_shape, describe_shape)
end

--- Creates a shape that matches a given string pattern.
-- @tparam string pattern the pattern to test for.
-- @treturn shape a new shape.
function pattern(pattern)
  checks.check_types('string')
  local base = {pattern = pattern}
  return create_shape('pattern', base, function(self, value)
    if type(value) ~= 'string' then
      return type_error('string', type(value))
    elseif not value:match(self.pattern) then
      return ("expected %s but got %s"):format(self, stringx.smart_quotes(value))
    end
  end, function(self)
    return self.pattern
  end)
end

local function validate_map(self, value)
  if type(value) ~= 'table' then
    return type_error(self, type(value))
  end

  local errors
  local function append_error(err)
    errors = errors or {}
    errors[#errors + 1] = err
  end

  local fail_fast = self.fail_fast
  local key_shape, value_shape = self.key_shape, self.value_shape
  for k, v in pairs(value) do
    local err = key_shape(k)
    if err then
      err = ("invalid map key (%s)"):format(err)
      if fail_fast then
        return err
      end
      append_error(err)
    else
      err = value_shape(v, value, k)
      if err then
        err = ("invalid map value %s (%s)"):format(format_key(k), err)
        if fail_fast then
          return err
        end
        append_error(err)
      end
    end
  end
  return aggregate_error(errors)
end

--- Creates a shape that verifies if a value is a map with keys and values of given types.
-- @tparam shape key_shape the shape for the they keys.
-- @tparam shape value_shape the shape for the they values.
-- @tparam table options a table containing the options of the array shape; valid options are:
--
-- - `fail_fast`: specifies if checking should stop at the first error or not.
function map_of(key_shape, value_shape, options)
  checks.check_types('shape', 'shape', '?table')
  local base = {key_shape = key_shape, value_shape = value_shape}
  if options then
    base.fail_fast = options.fail_fast
  end
  return create_shape('map', base, validate_map, function(self)
    return ("map <%s, %s>"):format(self.key_shape, self.value_shape)
  end)
end

--- Create a shape that verifies if a value is equal to a given value.
-- @param value the value to test for.
-- @tparam[opt] function eq a function used for the equality test.
-- @treturn shape a new shape.
function equal(value, eq)
  checks.check_types('any', '?function')
  local base = {expected = value, eq = eq}
  return create_shape('equal', base, function(self, x)
    if self.eq and not self.eq(self.expected, x) or not self.eq and self.expected ~= x then
      return type_error(self, x)
    end
  end, function(self)
    return format_value(self.expected)
  end)
end

--- Creates a shape that verifies if a value is accepted by _any_ of the given shapes; shapes are tested in the
-- same order they are passed to the function.
-- @tparam shape ... the shapes to test for.
-- @treturn shape a new shape.
function one_of(...)
  checks.check_types('+any')
  local shapes = tbl_pack(...)
  for i, x in ipairs(shapes) do
    if not is_shape(x) then
      shapes[i] = equal(x)
    end
  end
  local base = {shapes = shapes}
  return create_shape('one_of', base, function(self, value)
    for _, shape in ipairs(self.shapes) do
      local err = shape(value)
      if not err then
        return
      end
    end
    return type_error(self, value)
  end, function(self)
    return format_values(self.values, ' or ')
  end)
end

--- Creates a shape that verifies if a value is accepted by _each_ of the given shapes; shapes are tested in the
-- same order they are passed to the function.
-- @tparam shape ... the shapes to test for.
-- @treturn shape a new shape.
function all_of(...)
  checks.check_types('+any')
  local shapes = tbl_pack(...)
  for i, x in ipairs(shapes) do
    if not is_shape(x) then
      shapes[i] = equal(x)
    end
  end
  local base = {shapes = shapes}
  return create_shape('all_of', base, function(self, value)
    for _, shape in ipairs(self.shapes) do
      local err = shape(value)
      if err then
        return err
      end
    end
  end, function(self)
    return format_values(self.values, ' and ')
  end)
end

--- Creates a shape that verifies if a value is accepted by a given function.
--
-- The function will be invoked with the value to check as argument, and must
-- return `nil` if the value is accepted, otherwise an error message describing
-- why the check failed.
-- @tparam function validate the function to use to test the values.
-- @treturn shape a new shape.
function custom(validate)
  checks.check_types('function')
  local base = {validate = validate}
  return create_shape('custom', base, function(self, value)
    return self.validate(value)
  end, function(self)
    return ("custom function %s"):format(self.f)
  end)
end

--- Creates a shape that verifies if a value is withing a given range.
-- @param min the lower end of the range to test for (inclusive).
-- @param max the upper end of the range to test for (inclusive).
-- @tparam[opt] function le a function used to compare two values; the function is invoked with two arguments and
-- must return `true` if the first is less or equal than the second; otherwise `false`.
-- @treturn shape a new shape.
function range(min, max, le)
  checks.check_types('any', 'any', '?function')
  local base = {min = min, max = max, le = le}
  return create_shape('range', base, function(self, value)
    local ok
    if self.le then
      ok = self.le(self.min, value) and self.le(value, self.max)
    else
      ok = self.min <= value and value <= self.max
    end
    if not ok then
      return "value out of range"
    end
  end, function(self)
    return ('[%s, %s]'):format(self.min, self.max)
  end)
end

function min(min, le)
  checks.check_types('any', '?function')
  local base = {min = min, le = le}
  return create_shape('range', base, function(self, value)
    local ok
    if self.le then
      ok = self.le(self.min, value)
    else
      ok = self.min <= value
    end
    if not ok then
      return "value out of range"
    end
  end, function(self)
    return ('[%s, %s]'):format(self.min, self.max)
  end)
end

--- A shape for _boolean_ values.
-- @shape boolean
boolean = is_a('boolean')

--- A shape for _number_ values.
-- @shape number
number = is_a('number')

--- A shape for _string_ values.
-- @shape string
string = is_a('string')

--- A shape for _table_ values.
-- @shape table
table = is_a('table')

--- A shape for _coroutine_ values.
-- @shape thread
thread = is_a('thread')

--- A shape for _userdata_ values.
-- @shape userdata
userdata = is_a('userdata')

--- A shape for _function_ values.
-- @shape func
func = is_a('function')

--- A shape for _integer_ values.
-- @shape integer
integer = create_shape('integer', {}, function(self, value)
  local value_type = math_type(value) or type(value)
  if value_type ~= 'integer' then
    return type_error(self, value_type)
  end
end, function()
  return 'integer'
end)

--- A shape for _float_ values.
-- @shape float
float = create_shape('float', {}, function(self, value)
  local value_type = math_type(value)
  if value_type ~= 'float' then
    return type_error(self, value_type or type(value))
  end
end, function()
  return 'float'
end)

--- Alias for `integer`.
-- @shape int
int = integer

--- Alias for `boolean`.
-- @shape bool
bool = boolean

--- A shape that accepts anything.
-- @shape any
any = create_shape('any', {}, function()
end, function()
  return 'any'
end)

return M
