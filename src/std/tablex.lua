--- Extensions to the `table` module.
-- @module std.tablex
local M = {}

local stringx = require 'std.stringx'

local ipairs = ipairs
local next = next
local pairs = pairs
local rawequal = rawequal
local tostring = tostring
local type = type

local tbl_concat = table.concat
local tbl_pack = table.pack
local tbl_sort = table.sort

local _ENV = M

local Defaults = {
  eq = function(x, y)
    return x == y
  end,
  id = function(x)
    return x
  end,
  select_value = function(_, v)
    return v
  end,
}

--- Creates a table by generating a specified number of key-value pairs using the given generator.
-- @tparam integer n the number of key-value pairs to generate.
-- @tparam function f a generator function used to generate the key-value pairs of the
-- table; the argument of the function is the index of the key-value pair being generated.
-- @treturn table an table with the specified number of key-value pairs.
function with(n, f)
  local r = {}
  for i = 1, n do
    local k, v = f(i)
    r[k] = v
  end
  return r
end

--- Applies an accumulator function over a table.
-- @tparam table t the table to aggregate over.
-- @param[opt] acc the initial value of the accumulator.
-- @tparam accumulator f the accumulator function to be applied to each
-- key-value pair.
-- @return the final accumulator value.
function aggregate(t, acc, f)
  for k, v in pairs(t) do
    acc = f(k, v, acc)
  end
  return acc
end

--- Determines whether all the key-value pairs of a table satisfy a condition.
-- @tparam table t a table containing the key-value pairs to apply the predicate to.
-- @tparam predicate p a function to test each key-value pair for a condition.
-- @treturn boolean `true` if every key-value pair of the table satisfies the
-- specified predicate, or if the table is empty; otherwise `false`.
function all(t, p)
  for k, v in pairs(t) do
    if not p(k, v) then
      return false
    end
  end
  return true
end

--- Determines whether any key-value pair of a table satisfy a condition.
-- @tparam table t a table containing the key-value pairs to apply the predicate to.
-- @tparam predicate p a function to test each key-value pair for a condition.
-- @treturn boolean `true` if any key-value pair of the table satisfies the
-- specified predicate, or if the table is empty; otherwise `false`.
function any(t, p)
  for k, v in pairs(t) do
    if p(k, v) then
      return true
    end
  end
  return false
end

--- Calculates the sum of the table of numbers that are obtained by applying a
-- transform function to each key-value pair of a table.
-- @tparam table t a table to calculate the average of.
-- @tparam[opt] transform f a transform function to apply to each key-value pair.
-- @treturn number the sum of the projected key-value pairs.
function sum(t, f)
  f = f or Defaults.select_value
  local sum, n = 0, 0
  for k, v in pairs(t) do
    sum = sum + f(k, v)
    n = n + 1
  end
  return sum, n
end

--- Calculates the average of the values obtained by applying a
-- transform function to each key-value pair of a table.
-- @tparam table t a table to calculate the average of.
-- @tparam[opt] transform f a transform function to apply to each element.
-- @treturn number the average of the projected values; `nil` if the table is empty.
function avg(t, f)
  local s, n = sum(t, f)
  if n > 0 then
    return s / n
  end
end

--- Fills a table with the specified value.
-- @tparam table t a table to fill.
-- @param v the value to use to fill the table.
-- @treturn table the input table.
function fill(t, v)
  for k in pairs(t) do
    t[k] = v
  end
  return t
end

--- Projects each key-value pair of a table into a new value.
-- @tparam table t a table to invoke the transforms function on.
-- @tparam transform f a transform function to apply to each key-value pair; the
-- second parameter is the index of the key-value pair.
-- @treturn table a table whose key-value pairs are the the result of applying
-- the specified transform function on the key-value pairs of the input table.
function map(t, f)
  local r = {}
  for k, v in pairs(t) do
    local nk, nv = f(k, v)
    if nk ~= nil then
      r[nk] = nv
    end
  end
  return r
end

--- Groups the key-value pairs of a table according to a specified key selector.
-- @tparam table t a table whose key-value pairs to group.
-- @tparam key_selector f a function to extract the key for each key-value pair.
-- @treturn table a collection of key-value pairs where each key-value pair represents a
-- a projection over a group and its key.
function group_by(t, f)
  local r = {}
  for k, v in pairs(t) do
    local gk = f(k, v)
    if gk ~= nil then
      local rt = r[gk]
      if not rt then
        rt = {}
        r[gk] = rt
      end
      rt[k] = v
    end
  end
  return r
end

--- Applies a transform function to each value of a table and return the
-- the maximum of the projected values.
-- @tparam table t an table to determine the maximum value of.
-- @tparam transform f a transform function to apply to each value.
-- @return the key of maximum projected value in the table, or `nil` if the table is empty.
-- @return the maximum projected value in the table, or `nil` if the table is empty.
function max(t, f)
  f = f or Defaults.id
  local rk, rv
  for k, v in pairs(t) do
    local fv = f(v)
    if rv == nil or fv > rv then
      rk, rv = k, fv
    end
  end
  return rk, rv
end

--- Applies a transform function to each value of a table and returns the
-- maximum according to the projected values.
-- @tparam table t a table to determine the maximum value of.
-- @tparam transform f a transform function to apply to each value.
-- @return the key of maximum value in the table according to the transform function
-- or `nil` if the table is empty.
-- @return the maximum value in the table according to the transform function,
-- or `nil` if the table is empty.
function max_by(t, f)
  local rk, rv, fr
  for k, v in pairs(t) do
    local fv = f(v)
    if fr == nil or fv > fr then
      rk, rv, fr = k, v, fv
    end
  end
  return rk, rv
end

--- Applies a transform function to each value of a table and return the
-- the minimum of the projected values.
-- @tparam table t a table to determine the minimum value of.
-- @tparam[opt] transform f a transform function to apply to each value.
-- @return the minimum projected value in the table, or `nil` if the table is empty.
function min(t, f)
  f = f or Defaults.id
  local rk, rv
  for k, v in pairs(t) do
    local fv = f(v)
    if rv == nil or fv < rv then
      rk, rv = k, fv
    end
  end
  return rk, rv
end

--- Applies a transform function to each value of a table and returns the
-- minimum according to the projected values.
-- @tparam table t a table to determine the minimum value of.
-- @tparam transform f a transform function to apply to each value.
-- @return the minimum value in the table according to the transform function,
-- or `nil` if the table is empty.
function min_by(t, f)
  local rk, rv, fr
  for k, v in pairs(t) do
    local fv = f(v)
    if fr == nil or fv < fr then
      rk, rv, fr = k, v, fv
    end
  end
  return rk, rv
end

--- Creates a table with the keys of a table.
-- @tparam table t the table tho return the keys of.
-- @tparam[opt] boolean sorted if `true` the keys will be sorted.
-- @tparam[opt] comparator cmp a function used to compare each key.
-- @treturn table a table with the keys of the input table.
function keys(t, sorted, cmp)
  local r = {}
  for k in pairs(t) do
    r[#r + 1] = k
  end
  if sorted then
    tbl_sort(r, cmp)
  end
  return r
end

--- Creates an iterator over the values of a table.
-- @tparam table t the table tho return an iterator of.
-- @treturn function an iterator over the values of the input table.
function values(t)
  local k, v
  return function()
    k, v = next(t, k)
    return v
  end
end

--- Determines whether a table contains a specified value by using the given
-- equality comparer.
-- @tparam table t the table in which to locate the value.
-- @param v the value to locate in the table.
-- @tparam[opt] function eq the function to be used to test the value for equality.
-- @treturn boolean `true` if the table contains the specified value;
-- otherwise `false`.
function contains_value(t, v, eq)
  eq = eq or Defaults.eq
  for _, x in pairs(t) do
    if eq(x, v) then
      return true
    end
  end
  return false
end

--- Determines whether a table contains a specified key by using the given
-- equality comparer.
-- @tparam table t the table in which to locate the value.
-- @param k the key to locate in the table.
-- @tparam[opt] function eq the function to be used to test the key for equality.
-- @treturn boolean `true` if the table contains the specified key;
-- otherwise `false`.
function contains_key(t, k, eq)
  if not eq then
    return t[k] ~= nil
  end
  for x in pairs(t) do
    if eq(x, k) then
      return true
    end
  end
  return false
end

--- Counts how many key-value pairs of a table satisfy a condition.
-- @tparam table t a table containing the key-value pairs to be tested and counted.
-- @tparam predicate p a function to test each key-value pair.
-- @treturn integer the number of key-value pairs satisfying the specified predicate.
function count(t, p)
  local n = 0
  for k, v in pairs(t) do
    if p(k, v) then
      n = n + 1
    end
  end
  return n
end

local function _eq(t1, t2, eq)

  if rawequal(t1, t2) then
    return true
  end

  if t1 == nil and t2 ~= nil then
    return false
  elseif t1 ~= nil and t2 == nil then
    return false
  end

  local function _eqv(x, y)
    local tx = type(x)
    local ty = type(y)
    if y == nil or ty ~= tx then
      return false
    elseif tx == 'table' then
      if not _eq(x, y, eq) then
        return false
      end
    elseif not eq(x, y) then
      return false
    end
    return true
  end

  local k1, v1, k2, v2
  eq = eq or Defaults.eq
  while true do
    k1, v1 = next(t1, k1)
    k2, v2 = next(t2, k2)
    if k1 == nil then
      return k2 == nil
    elseif k2 == nil then
      return false
    end
    if k1 == k2 then
      local v21 = t2[k1]
      if not _eqv(v1, v21) then
        return false
      end
    else
      local v12, v21 = t1[k2], t2[k1]
      if v12 == nil or v21 == nil or not _eqv(v1, v21) or not _eqv(v2, v12) then
        return false
      end
    end
  end
end

--- Compares two tables for equality.
-- @tparam table t1 the first table to compare.
-- @tparam table t2 the second table to compare.
-- @tparam function[opt] eq the function used to test the table's values for equality.
-- @treturn bool `true` if the tables are equals, otherwise `false`.
function eq(t1, t2, eq)
  return _eq(t1, t2, eq)
end

--- Filters a table based on a predicate.
-- @tparam table t the table containing the key-value pairs to be tested.
-- @tparam predicate p the function used to test each key-value pair.
-- @treturn table a table containing key-value pairs satisfying the condition.
function filter(t, p)
  local r = {}
  for k, v in pairs(t) do
    if p(k, v) then
      r[k] = v
    end
  end
  return r
end

--- Removes all key-value pairs from a table.
-- @tparam table t the table to wipe.
function clear(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

--- Clones the given table.
-- @tparam table t the table to clone.
-- @treturn table a clone of the given table.
function clone(t)
  return copy(t, {})
end

--- Copies the key-value pairs from a table to another table.
-- @tparam table src the table to copy from.
-- @tparam table dst the table to copy to.
-- @tparam[opt] table keys a list of keys to copy; if `nil` all the keys will be copied.
-- @treturn table the _dst_ table.
function copy(src, dst, keys)
  if keys then
    for _, k in ipairs(keys) do
      if src[k] ~= nil then
        dst[k] = src[k]
      end
    end
  else
    for k, v in pairs(src) do
      dst[k] = v
    end
  end
  return dst
end

-- Searches a table for the first key-value pair satisfying a specified
-- condition.
-- @tparam table t an table to be searched.
-- @tparam predicate p a function to test each key-value pair.
-- @return the first key-value pair satisfying the specified condition, otherwise `nil`.
function find(t, p)
  for k, v in pairs(t) do
    if p(k, v) then
      return k, v
    end
  end
end

--- Determines whether a table is empty or not.
-- @tparam table t a table containing the key-value pairs to be tested.
-- @treturn boolean `true` if the table is empty, otherwise `false`.
function is_empty(t)
  return next(t) == nil
end

-- Searches a table for the first key-value pair satisfying a specified
-- condition, and remove it.
-- @tparam table t a table to be searched.
-- @tparam predicate p a function to test each key-value pair.
-- @treturn boolean `true` if any key-value pair is removed; otherwise `false`.
function remove_if(t, p)
  for k, v in pairs(t) do
    if p(k, v) then
      t[k] = nil
      return true
    end
  end
  return false
end

--- Searches a table for all the key-value pairs satisfying a specified
-- condition, and remove them.
-- @tparam table t a table to be searched.
-- @tparam predicate p a function to test each key-value pair.
-- @treturn integer the number of key-value pairs removed.
function remove_all_if(t, p)
  local n = 0
  for k, v in pairs(t) do
    if p(k, v) then
      t[k] = nil
      n = n + 1
    end
  end
  return n
end

--- Removes the specified keys from a table.
-- @tparam table t the table to remove the keys from.
-- @tparam table keys the list of keys to remove.
function remove_keys(t, keys)
  for _, k in pairs(keys) do
    t[k] = nil
  end
end

--- Returns the string representation of a table.
-- @tparam table t the table to return the string representation of.
-- @treturn string a string representing the given table.
function to_string(t)

  local b, seen = {}, {}
  local add_value -- forward declaration
  local function add_table(tt)
    if seen[tt] then
      b[#b + 1] = '<table>'
      return
    end
    seen[tt] = true

    local kk = keys(tt, true)
    b[#b + 1] = '{'
    for _, k in pairs(kk) do
      local v = tt[k]
      b[#b + 1] = '['
      add_value(k)
      b[#b + 1] = ']='
      add_value(v)
      b[#b + 1] = ','
    end
    if b[#b] == ',' then
      b[#b] = nil
    end
    b[#b + 1] = '}'
  end

  add_value = function(v)
    if v == nil then
      b[#b + 1] = 'nil'
      return
    end

    local tv = type(v)
    if tv == 'string' then
      b[#b + 1] = stringx.smart_quotes(v)
    elseif tv == 'number' then
      b[#b + 1] = tostring(v)
    elseif tv == 'boolean' then
      b[#b + 1] = tostring(v)
    elseif tv == 'table' then
      add_table(v)
    else
      b[#b + 1] = '<'
      b[#b + 1] = tostring(v)
      b[#b + 1] = '>'
    end
  end

  add_table(t)
  return tbl_concat(b)
end

--- Merges the given tables into a new one.
-- @tparam table t1 the first table to merge.
-- @tparam table t2 the second table to merge.
-- @param ... more tables.
-- @tparam[optchain] function f a function invoked on each duplicated key;
-- the first arguments is the ket, the second is the old value, and the third is the new value.
-- @treturn table a new table containing the key-value pairs of the input tables.
function merge(...)
  local tables = tbl_pack(...)
  local f
  if type(tables[#tables]) == 'function' then
    f = tables[#tables]
    tables[#tables] = nil
  end

  local r = {}
  for _, t in ipairs(tables) do
    for k, v in pairs(t) do
      if r[k] ~= nil and f then
        r[k] = f(k, r[k], v)
      else
        r[k] = v
      end
    end
  end
  return r
end

-- Updates a table with values of another specified table.
-- @tparam table t1 a table to update.
-- @tparam table t2 the table containing the updated values.
-- @tparam[opt] table keys the list of keys to update.
function update(t1, t2, keys)
  if keys then
    for _, k in ipairs(keys) do
      if t1[k] ~= nil and t2[k] ~= nil then
        t1[k] = t2[k]
      end
    end
  else
    for k in pairs(t1) do
      if t2[k] ~= nil then
        t1[k] = t2[k]
      end
    end
  end
  return t1
end

--- Invokes a function on each key-value pair of a table.
-- @tparam table t the table to invoke the function on.
-- @tparam function f a function to apply to invoke on each key-value pair.
function each_pair(t, f)
  for k, v in pairs(t) do
    f(k, v)
  end
end

return M

--- Function Types
-- @section fn_types

--- Signature of a predicate function.
-- @function predicate
-- @param k the key-value pair's key.
-- @param v the key-value pair's value.
-- @treturn boolean `true` if the key-value pair matches the condition, otherwise `false`.

--- Signature of a key selector function.
-- @function key_selector
-- @param k the key-value pair's key.
-- @param v the key-value pair's value.
-- @return any value that can be used as a table key.

--- Signature of a transform function.
-- @function transform
-- @param k the key-value pair's key.
-- @param v the key-value pair's value.
-- @return the transformed key, or `nil` the key-value pair must be skipped.
-- @return the transformed value, or `nil` the key-value pair must be skipped.
