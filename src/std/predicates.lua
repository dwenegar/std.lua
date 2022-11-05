--- Ready to use predicates and predicate factories for several test cases.
-- A predicate is a function that evaluate a condition and return either `true` or `false`.
-- @module std.predicates
local M = {}

local type = type
local math_type = math.type

local _ENV = M
--- Returns `true` if the given argument is a number.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a number, otherwise `false`.
function is_number(x)
  return type(x) == 'number'
end

--- Returns `true` if the given argument is an integer.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is an integer, otherwise `false`.
function is_integer(x)
  return math_type(x) == 'integer'
end

--- Returns `true` if the given argument is a string.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a string, otherwise `false`.
function is_string(x)
  return type(x) == 'string'
end

--- Returns `true` if the given argument is a table.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a table, otherwise `false`.
function is_table(x)
  return type(x) == 'table'
end

--- Returns `true` if the given argument is a function.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a function, otherwise `false`.
function is_function(x)
  return type(x) == 'function'
end

--- Returns `true` if the given argument is `nil`.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is `nil`, otherwise `false`.
function is_nil(x)
  return type(x) == 'nil'
end

--- Returns `true` if the given argument is a coroutine.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a coroutine, otherwise `false`.
function is_thread(x)
  return type(x) == 'thread'
end

--- Returns `true` if the given argument is a userdata.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a userdata, otherwise `false`.
function is_userdata(x)
  return type(x) == 'userdata'
end

--- Returns `true` if the given argument is a boolean.
-- @param x the value to test.
-- @treturn boolean `true` if the given argument is a boolean, otherwise `false`.
function is_boolean(x)
  return type(x) == 'boolean'
end

--- Returns a function implementing the *greater than* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *greater than* the given value.
-- @param x the value used for comparison (must support the `<` operator).
-- @treturn function a function implementing the *greater than* test for the given argument
function gt(x)
  return function(value)
    return x < value
  end
end

--- Returns a function implementing the *greater than or equal to* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *greater than or equal to* the given value.
-- @param x the value used for comparison (must support the `<=` operator).
-- @treturn function a function implementing the *greater than or equal to* test for the given argument
function ge(x)
  return function(value)
    return x <= value
  end
end

--- Returns a function implementing the *less than* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *less than* the given value.
-- @param x the value used for comparison (must support the `<=` operator).
-- @treturn function a function implementing the *less than* test for the given argument
function lt(x)
  return function(value)
    return value < x
  end
end

--- Returns a function implementing the *less than or equal* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *less than or equals* the given value.
-- @param x the value used for comparison (must support the `<` operator).
-- @treturn function a function implementing the *less than or equal* test for the given argument
function le(x)
  return function(value)
    return value <= x
  end
end

--- Returns a function implementing the *equal to* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *equals to* the given value.
-- @param x the value used for comparison.
-- @treturn function a function implementing the *equal to* test for the given argument
function eq(x)
  return function(value)
    return value == x
  end
end

--- Returns a function implementing the *not equal to* predicate for the given argument.
-- A factory method that returns a single-argument function that test whether its argument is
-- *not equal to* the given value.
-- @param x the value used for comparison.
-- @treturn function a function implementing the *not equal to* test for the given argument
function neq(x)
  return function(value)
    return value ~= x
  end
end

--- Returns a function always returning the specified value.
-- @param x the value to return.
-- @treturn function a function returning the specified value.
function always(x)
  return function()
    return x
  end
end

return M
