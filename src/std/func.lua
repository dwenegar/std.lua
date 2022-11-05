--- Functional programming support module.
-- @module std.func
local M = {}

local load = load
local tbl_pack = table.pack
local tbl_unpack = table.unpack

local _ENV = M

--- Composes the specified functions.
-- @tparam function f the first function to be composed.
-- @tparam function g the second function to be composed.
-- @treturn function a new function calculating `f(g(...))`.
function compose(f, g)
  return function(...)
    return f(g(...))
  end
end

--- Creates a partial application of the given function.
-- @param a the argument to fix.
-- @tparam function f the function.
-- @treturn function a new partial application of `f` using `a`.
function partial(a, f)
  return function(...)
    return f(a, ...)
  end
end

--- Curries the given function.
-- @tparam function f the function to be curried.
-- @treturn function the curried function.
function curry(f)
  return function(a)
    return partial(a, f)
  end
end

--- Creates a function that always returns the specified value.
-- @param v the value to be returned.
-- @treturn function a function returning always the specified value.
function always(v)
  return function()
    return v
  end
end

--- The identity function.
-- @param v the value to be returned.
-- @return the input value unmodified.
function identity(v)
  return v
end

--- Memoizes a function with no argument.
-- @tparam function f the function to be memoized.
-- @treturn function the memoized function.
function memoize0(f)
  local value
  return function()
    if not value then
      value = tbl_pack(f())
    end
    return tbl_unpack(value)
  end
end

local function get_cache(cache, k1, k2, k3)
  if not cache[k1] then
    cache[k1] = {}
  end
  cache = cache[k1]
  if k2 == nil then
    return cache
  end
  if not cache[k2] then
    cache[k2] = {}
  end
  cache = cache[k2]
  if k3 == nil then
    return cache
  end
  if not cache[k3] then
    cache[k3] = {}
  end
  return cache[k3]
end

local Nil = {}
local function mask_nil(v)
  if v == nil then
    return Nil
  end
  return v
end

--- Memoizes a function with one argument.
-- @tparam function f the function to be memoized.
-- @treturn function the memoized function.
function memoize1(f)
  local cache = {}
  return function(arg1)
    local k1 = mask_nil(arg1)
    if not cache[k1] then
      cache[k1] = tbl_pack(f(arg1))
    end
    return tbl_unpack(cache[k1])
  end
end

--- Memoizes a function with two arguments.
-- @tparam function f the function to be memoized.
-- @treturn function the memoized function.
function memoize2(f)
  local cache = {}
  return function(arg1, arg2)
    local k1, k2 = mask_nil(arg1), mask_nil(arg2)
    local cache2 = get_cache(cache, k1)
    if not cache2[k2] then
      cache2[k2] = tbl_pack(f(arg1, arg2))
    end
    return tbl_unpack(cache2[k2])
  end
end

--- Memoizes a function with threw arguments.
-- @tparam function f the function to be memoized.
-- @treturn function the memoized function.
function memoize3(f)
  local cache = {}
  return function(arg1, arg2, arg3)
    local k1, k2, k3 = mask_nil(arg1), mask_nil(arg2), mask_nil(arg3)
    local cache3 = get_cache(cache, k1, k2)
    if not cache3[k3] then
      cache3[k3] = tbl_pack(f(arg1, arg2, arg3))
    end
    return tbl_unpack(cache3[k3])
  end
end

--- Memoizes a function with four arguments.
-- @tparam function f the function to be memoized.
-- @treturn function the memoized function.
function memoize4(f)
  local cache = {}
  return function(arg1, arg2, arg3, arg4)
    local k1, k2, k3, k4 = mask_nil(arg1), mask_nil(arg2), mask_nil(arg3), mask_nil(arg4)
    local cache4 = get_cache(cache, k1, k2, k3)
    if not cache4[k4] then
      cache4[k4] = tbl_pack(f(arg1, arg2, arg3, arg4))
    end
    return tbl_unpack(cache4[k4])
  end
end

--- Compiles a string representing a lambda expression into a Lua function.
--
-- A lambda expression has this form:
--
--   `(input-parameters) => expression`
--
-- @function lambda
-- @tparam string s a valid lambda string.
-- @treturn function the compiled lambda string, or `nil` if the compilation fails.
-- @treturn string an error message if the compilation fails, otherwise `nil`.
local lambda_cache = {}
function lambda(s)
  s = s:match('^%s*(.-)%s*$')
  if lambda_cache[s] then
    return lambda_cache[s]
  end

  local params, body = s:match('^%(%s*([^%(]*)%s*%)%s*=>%s*(.+)$')
  if not params then
    return nil, ("invalid lambda expression: '%s'"):format(s)
  end

  local chunk
  if not params then
    chunk = ('return %s'):format(body)
  elseif #params == 0 then
    chunk = ('return %s'):format(body)
  else
    chunk = ('%s = ...; return %s'):format(params, body)
  end

  local f, err = load(chunk)
  if err then
    return nil, ("invalid lambda expression: '%s' (%s)"):format(s, err)
  end

  lambda_cache[s] = f
  return f
end

return M
