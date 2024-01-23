--- Provides methods for creating, manipulating, and searching arrays.
-- @module std.array
local M = {}

local stringx = require 'std.stringx'

local ipairs = ipairs
local pairs = pairs
local rawequal = rawequal
local tostring = tostring
local type = type

local math_max = math.max
local math_min = math.min
local math_random = math.random

local tbl_concat = table.concat
local tbl_insert = table.insert
local tbl_move = table.move
local tbl_remove = table.remove

local _ENV = M

local Defaults = {
  eq = function(x, y)
    return x == y
  end,
  cmp = function(lhs, rhs)
    if lhs < rhs then
      return -1
    elseif lhs > rhs then
      return 1
    end
    return 0
  end,
  id = function(x)
    return x
  end,
  make_pair = function(x, y)
    return {x, y}
  end
}

local function normalize(a, from, to, f)
  if type(from) == 'function' then
    f, from, to = from, 1, #a
  elseif type(to) == 'function' then
    f, to = to, #a
  end
  from = from or 1
  to = to or #a
  if from < 0 then
    from = from + #a + 1
  end
  if to < 0 then
    to = to + #a + 1
  end
  from = math_max(1, from)
  to = math_min(#a, to)
  return from, to, f
end

--- Creates an array using the specified values.
-- @param ... the values to be placed in the array.
-- @treturn table a new array with the given values.
function of(...)
  return {...}
end

--- Creates an array containing a sequence of numbers using the given parameters.
-- @tparam integer n the length of the sequence to generate.
-- @tparam integer from the first value of the sequence.
-- @tparam[opt] number step the difference between two consecutive values of the
-- sequence.
-- @treturn table an array of numbers of the specified length.
function seq(n, from, step)
  from = from or 0
  step = step or 1
  local r = {}
  for i = 1, n do
    r[i], from = from, from + step
  end
  return r
end

--- Creates an array of the specified length using a generator function.
-- @tparam integer n the length of the array to generate.
-- @tparam function f a generator function used to generate the elements of the
-- array; the argument of the function is the index of the element being generated.
-- @treturn table an array of the specified length.
function with(n, f)
  local r = {}
  for i = 1, n do
    r[i] = f(i)
  end
  return r
end

--- Creates an array of the specified length using the given value.
-- @param v the value to generate the array with.
-- @tparam integer n the length of the array to generate.
-- @treturn table an array of the specified length containing the given value.
function rep(v, n)
  local r = {}
  for i = 1, n do
    r[i] = v
  end
  return r
end

--- Concatenates the given arrays.
-- @tparam table ... the arrays to concatenate.
-- @treturn table an array containing the concatenated elements of the input arrays.
function cat(...)
  local r = {}
  for _, x in ipairs({...}) do
    copy(x, r, #r + 1)
  end
  return r
end

--- Creates a set from a range of elements of an array.
-- @tparam table a an array to create a set from.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @treturn table a set containing the elements of the input array.
function to_set(a, from, to)
  if #a == 0 then
    return {}
  end
  from, to = normalize(a, from, to)
  local r = {}
  for i = from, to do
    r[a[i]] = true
  end
  return r
end

--- Creates a map from a range of elements of an array.
-- @tparam table a an array to create a set from.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @tparam[optchain] function f function used to calculate the map values.
-- @treturn table a map whose keys are the value of the input array, and the
-- values are the result of the application of `f`.
function to_map(a, from, to, f)
  from, to, f = normalize(a, from, to, f)
  local r = {}
  f = f or Defaults.id
  for i = from, to do
    local x = a[i]
    r[x] = f(x)
  end
  return r
end

--- Creates a bag from a range of elements of an array.
-- @tparam table a an array to create a set from.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @treturn table containing the elements of the input array TODO
function to_bag(a, from, to)
  if #a == 0 then
    return {}
  end
  from, to = normalize(a, from, to)
  local r = {}
  for i = from, to do
    local x = a[i]
    r[x] = (r[x] or 0) + 1
  end
  return r
end

--- Applies an accumulator function over an array.
-- @tparam table a an array to aggregate over.
-- @param acc the initial value of the accumulator.
-- @tparam function f an accumulator function to be applied to each element;
-- the second argument is the previous accumulator's value.
-- @return the final accumulator value.
function aggregate(a, acc, f)
  for i = 1, #a do
    acc = f(a[i], acc)
  end
  return acc
end

--- Calculates the sum of the array of numbers that are obtained by applying a
-- transform function to each element of an array.
-- @tparam table a an array to calculate the average of.
-- @tparam[opt] transform f a transform function to apply to each element.
-- @treturn number the sum of the projected values.
function sum(a, f)
  f = f or Defaults.id
  local sum = 0
  for i = 1, #a do
    sum = sum + f(a[i])
  end
  return sum
end

--- Calculates the average of the array of numbers that are obtained by applying a
-- transform function to each element of an array.
-- @tparam table a an array to calculate the average of.
-- @tparam[opt] transform f a transform function to apply to each element.
-- @treturn number the average of the projected values; `nil` if the array is empty.
function avg(a, f)
  if #a == 0 then
    return
  end
  return sum(a, f) / #a
end

--- Determines whether all the elements of an array satisfy a condition.
-- @tparam table a an array containing the elements to apply the predicate to.
-- @tparam predicate p a function to test each element for a condition.
-- @treturn boolean `true` if every element of the array satisfies the
-- specified predicate, or if the array is empty, otherwise `false`.
function all(a, p)
  for i = 1, #a do
    if not p(a[i]) then
      return false
    end
  end
  return true
end

--- Determines whether any element of an array satisfy a condition.
-- @tparam table a an array containing the elements to apply the predicate to.
-- @tparam predicate p a function to test each element for a condition.
-- @treturn boolean `true` if any element of the array satisfies the
-- specified predicate, or if the array is empty, otherwise `false`.
function any(a, p)
  for i = 1, #a do
    if p(a[i]) then
      return true
    end
  end
  return #a == 0
end

--- Counts how many elements of an array satisfy a condition.
-- @tparam table a an array containing the elements to be tested and counted.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn integer the number of elements satisfying the specified predicate.
function count(a, p)
  local n = 0
  for i = 1, #a do
    if p(a[i], i) then
      n = n + 1
    end
  end
  return n
end

--- Returns distinct elements from an array.
-- @tparam table a the array to remove the duplicated elements from.
-- @tparam[opt] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn table a new array containing distinct elements from the input array.
function distinct(a, eq)
  if #a == 0 then
    return {}
  end

  local r, seen = {}, {}
  local function contains_slow(x)
    for y in pairs(seen) do
      if eq(x, y) then
        return true
      end
    end
    return false
  end

  local function contains_fast(x)
    return seen[x]
  end

  local contains = eq and contains_slow or contains_fast

  for i = 1, #a do
    local x = a[i]
    if not contains(x) then
      r[#r + 1] = x
      seen[x] = true
    end
  end

  return r
end

--- Produces the set difference of two arrays.
-- @tparam table a an array whose elements that are not also in `a2` will be returned.
-- @tparam table exclusions an array whose elements that also occur in `a1` will cause those
-- elements to be removed from the returned sequence.
-- @treturn table an array containing the set difference of the two input arrays.
function except(a, exclusions)
  if #a == 0 then
    return {}
  end
  local r, seen = {}, to_set(exclusions)
  for _, x in ipairs(a) do
    if not seen[x] then
      r[#r + 1] = x
    end
  end
  return r
end

--- Returns the set intersection of two arrays.
-- @tparam table a1 an array whose distinct elements that also appear in `a2` will be returned.
-- @tparam table a2 an array whose distinct elements that also appear in `a1` will be returned.
-- @treturn table an array that contains the elements that appear in `a1` and `a2`.
function intersect(a1, a2)
  if #a1 == 0 or #a2 == 0 then
    return {}
  end
  local r, seen = {}, to_bag(a2)
  for _, x in ipairs(a1) do
    local n = seen[x]
    if n then
      r[#r + 1] = x
      n = n - 1
      seen[x] = n > 0 and n
    end
  end
  return r
end

--- Filters an array based on a predicate.
-- @tparam table a an array to filter.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn table an array containing elements from the input array satisfying
-- the specified condition.
function filter(a, p)
  if #a == 0 then
    return {}
  end
  local r = {}
  for i, v in ipairs(a) do
    if p(v, i) then
      r[#r + 1] = v
    end
  end
  return r
end

--- Projects each element of an array into a new value.
-- @tparam table a an array to invoke the transforms function on.
-- @tparam transform f a transform function to apply to each element; the
-- second parameter is the index of the element.
-- @treturn table an array whose elements are the the result of applying
-- the specified transform function on the elements of the input array.
function map(a, f)
  local r = {}
  for i, v in ipairs(a) do
    r[#r + 1] = f(v, i)
  end
  return r
end

--- Applies a transform function to the elements of an array and flatten the
-- resulting array.
-- @tparam table a the array to invoke the transformation function on.
-- @tparam function f a transform function to apply to each element; the
-- second parameter is the position of the element in the array; if the function
-- returns `nil` the element will be skipped; the function must return an array.
-- @treturn table a new array whose elements are the the result of invoking
-- the specified transform function on the elements of an array.
function map_many(a, f)
  local r = {}
  for i, v in ipairs(a) do
    local c = f(v, i)
    if c then
      copy(c, r, #r + 1)
    end
  end
  return r
end

--- Groups the elements of an array according to a specified key selector.
-- @tparam table a an array whose elements to group.
-- @tparam function f a function to extract the key for each element (see @{key_selector}).
-- @treturn table a collection of elements where each element represents a
-- a projection over a group and its key.
function group_by(a, f)
  local r = {}
  for i, x in ipairs(a) do
    local gk = f(x, i)
    if gk ~= nil then
      local t = r[gk]
      if not t then
        t = {}
        r[gk] = t
      end
      t[#t + 1] = x
    end
  end
  return r
end

--- Applies a transform function to each element of an array and return the
-- the maximum of the projected values.
-- @tparam table a an array to determine the maximum value of.
-- @tparam[opt] transform f a transform function to apply to each element.
-- @return the maximum projected value in the array, or `nil` if the array is empty.
function max(a, f)
  if #a == 0 then
    return
  end
  f = f or Defaults.id
  local fr
  for _, x in ipairs(a) do
    local fx = f(x)
    if fr == nil or fx > fr then
      fr = fx
    end
  end
  return fr
end

--- Applies a transform function to each element of an array and returns the
-- maximum according to the projected values.
-- @tparam table a an array to determine the maximum value of.
-- @tparam transform f a transform function to apply to each element.
-- @return the maximum value in the array according to the transform function,
-- or `nil` if the array is empty.
function max_by(a, f)
  if #a == 0 then
    return
  end
  local r, fr
  for _, x in ipairs(a) do
    local fx = f(x)
    if fr == nil or fx > fr then
      r, fr = x, fx
    end
  end
  return r
end

--- Applies a transform function to each element of an array and return the
-- the minimum of the projected values.
-- @tparam table a an array to determine the minimum value of.
-- @tparam[opt] transform f a transform function to apply to each element.
-- @return the minimum projected value in the array, or `nil` if the array is empty.
function min(a, f)
  if #a == 0 then
    return
  end
  f = f or Defaults.id
  local fr
  for _, x in ipairs(a) do
    local fx = f(x)
    if fr == nil or fx < fr then
      fr = fx
    end
  end
  return fr
end

--- Applies a transform function to each element of an array and returns the
-- minimum according to the projected values.
-- @tparam table a an array to determine the minimum value of.
-- @tparam transform f a transform function to apply to each element.
-- @return the minimum value in the array according to the transform function,
-- or `nil` if the array is empty.
function min_by(a, f)
  if #a == 0 then
    return
  end
  local r, fr
  for _, x in ipairs(a) do
    local fx = f(x)
    if r == nil or fx < fr then
      r, fr = x, fx
    end
  end
  return r
end

--- Removes a specified number of elements from the beginning of an array.
-- @tparam table a an array to return elements from.
-- @tparam[opt=1] integer n the number of elements to return.
-- @treturn table an array containing the elements occurring after the specified
-- index in the input array.
function drop(a, n)
  n = n or 1
  if #a > 0 and n > 0 then
    if n < #a then
      tbl_move(a, n + 1, #a, 1, a)
    end
    resize(a, #a - n)
  end
end

--- Removes elements from the beginning of an array as long as they satisfy a specified condition.
-- @tparam table a an array to return elements from.
-- @tparam function p a function to test each element (see @{predicate}).
function drop_while(a, p)
  if #a > 0 then
    local n = 0
    for _, x in ipairs(a) do
      if p(x) then
        n = n + 1
      else
        break
      end
    end
    drop(a, n)
  end
end

--- Returns a specified number of elements from the start an array.
-- @tparam table a an array to return elements from.
-- @tparam[opt=1] integer n the number of elements to return.
-- @treturn table an array containing the specified number of elements from
-- the start of the input array.
function take(a, n)
  n = n or 1
  if #a == 0 or n == 0 then
    return {}
  end
  return tbl_move(a, 1, n or 1, 1, {})
end

--- Returns elements from an array as long as a specified condition is true.
-- @tparam table a an array to return elements from.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn table an array containing elements from the input array occurring
-- before the first element not satisfying the specified condition.
function take_while(a, p)
  local t = {}
  for _, v in ipairs(a) do
    if not p(v) then
      break
    end
    t[#t + 1] = v
  end
  return t
end

--- Applies a specified function to the corresponding elements of two arrays,
-- and returns the resulting elements.
-- @tparam table a1 the first array to merge.
-- @tparam table a2 the second array to merge.
-- @tparam function f a function that specifies how to merge the elements
-- from the two arrays.
-- @treturn table an array containing merged elements of the input arrays.
function zip(a1, a2, f)
  f = f or Defaults.make_pair
  local r = {}
  for i = 1, math_min(#a1, #a2) do
    local x, y = a1[i], a2[i]
    r[i] = f(x, y)
  end
  return r
end

--- Searches a range of elements in a sorted array for a value using the
-- specified comparer.
-- @tparam table a the sorted array to be searched.
-- @param v the value to search.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[opt] function cmp the comparer used to compare values (see @{comparer}).
-- @treturn integer the index of the specified value in the array; or `nil` if
-- the element is not found.
function binary_search(a, v, from, to, cmp)
  from, to, cmp = normalize(a, from, to, cmp)
  cmp = cmp or Defaults.cmp
  while from <= to do
    local mid = (from + to) // 2
    local test = cmp(a[mid], v)
    if test == 0 then
      return mid
    elseif test > 0 then
      to = mid - 1
    else
      from = mid + 1
    end
  end
end

--- Removes all the elements from an array.
-- @function clear
-- @tparam table a an array to clear.
function clear(a)
  resize(a, 0)
end

--- Copies a range of elements of an array to another array starting at the
-- specified index.
-- @tparam table src the array to copy from.
-- @tparam[opt] integer src_from the starting index of the range to copy.
-- @tparam[optchain] integer src_to the ending index of the range to copy.
-- @tparam table dst the array to copy to.
-- @tparam[opt] integer dst_from the index at which copying begins.
-- @treturn table the destination array.
function copy(src, src_from, src_to, dst, dst_from)
  if type(src_from) == 'table' then
    dst, dst_from, src_from, src_to = src_from, src_to, 1, #src
  elseif type(src_to) == 'table' then
    dst, dst_from, src_to = src_to, dst, #src
  end
  dst = dst or {}
  src_from, src_to = normalize(src, src_from, src_to)
  if src_from > src_to then
    return dst
  end
  return tbl_move(src, src_from, src_to, dst_from or 1, dst)
end

--- Compares two arrays using a specified comparer.
-- @tparam table a1 the first array to be compared.
-- @tparam table a2 the second array to be compared.
-- @tparam function cmp the comparator used to compare values (see @{comparer}).
-- @treturn int a positive number if the first array is greater than the second;
-- a negative number if the second array is greater than the first; zero otherwise.
function cmp(a1, a2, cmp)
  if not a1 then
    return not a2 and 0 or -1
  elseif not a2 then
    return 1
  elseif rawequal(a1, a2) then
    return 0
  elseif #a1 < #a2 then
    return -1
  elseif #a1 > #a2 then
    return 1
  end

  cmp = cmp or Defaults.cmp
  for i = 1, #a1 do
    local t = cmp(a1[i], a2[i])
    if t ~= 0 then
      return t
    end
  end
  return 0
end

--- Compares two arrays for equality using the specified equality comparer.
-- @tparam table a1 the first array to be compared.
-- @tparam table a2 the second array to be compared.
-- @tparam[opt] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn boolean `true` if the arrays are equals, otherwise `false`.
function eq(a1, a2, eq)
  if not a1 then
    return not a2
  elseif not a2 then
    return false
  elseif rawequal(a1, a2) then
    return true
  elseif #a1 ~= #a2 then
    return false
  end

  eq = eq or Defaults.eq
  for i = 1, #a1 do
    if not eq(a1[i], a2[i]) then
      return false
    end
  end
  return true
end

-- Searches a range of elements of an array for the first element satisfying a
-- specified condition.
-- @tparam table a an array to be searched.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam function p a function to test each element (see @{predicate}).
-- @return the first element satisfying the specified condition, otherwise `nil`.
-- @treturn integer the index of the first element satisfying the specified condition, otherwise `nil`.
function find(a, from, to, p)
  if #a == 0 then
    return
  end
  from, to, p = normalize(a, from, to, p)
  for i = from, to do
    if p(a[i]) then
      return a[i], i
    end
  end
end

-- Searches a range of elements of an array for the last element satisfying a
-- specified condition.
-- @tparam table a an array to be searched.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam function p a function to test each element (see @{predicate}).
-- @return the last element satisfying the specified condition, otherwise `nil`.
-- @treturn integer the index of the last element satisfying the specified condition, otherwise `nil`.
function find_last(a, from, to, p)
  if #a == 0 then
    return
  end
  from, to, p = normalize(a, from, to, p)
  for i = to, from, -1 do
    if p(a[i]) then
      return a[i], i
    end
  end
end

--- Searches a range of elements of an array for all the elements satisfying a
-- specified condition.
-- @tparam table a an array to be searched.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn table the elements satisfying the specified condition, otherwise `nil`.
function find_all(a, from, to, p)
  if #a == 0 then
    return {}
  end
  from, to, p = normalize(a, from, to, p)
  local r = {}
  for i = from, to do
    if p(a[i]) then
      r[#r + 1] = a[i]
    end
  end
  return r
end

--- Determines whether the specified range of an array contains a specified value
-- using the specified equality comparer.
-- @tparam table a an array in which to locate the value.
-- @param v the value to locate in the array.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[optchain] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn boolean `true` if the array contains the specified value; `false` otherwise.
function contains(a, v, from, to, eq)
  return index_of(a, v, from, to, eq) ~= nil
end

--- Determines whether an array is empty or not.
-- @tparam table a an array containing the elements to be tested.
-- @treturn boolean `true` if the array is empty, otherwise `false`.
function is_empty(a)
  return #a == 0
end

--- Searches an array for the specified value using a specified equality
-- comparer, and returns the index of the first occurrence within the specified
-- range.
-- @tparam table a an array to be searched.
-- @param v the value to look for.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[optchain] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn integer the index of the first occurrences of the specified value,
-- if found, otherwise `nil`.
function index_of(a, v, from, to, eq)
  if #a == 0 then
    return
  end
  from, to, eq = normalize(a, from, to, eq)
  eq = eq or Defaults.eq
  for i = from, to do
    if eq(a[i], v) then
      return i
    end
  end
end

--- Searches an array for the specified value using a specified equality
-- comparer, and returns the index of the last occurrence within the specified
-- range.
-- @tparam table a an array to be searched.
-- @param v the value to look for.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[optchain] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn integer the index of the last occurrences of the specified value,
-- if found, otherwise `nil`.
function last_index_of(a, v, from, to, eq)
  if #a == 0 then
    return
  end
  from, to, eq = normalize(a, from, to, eq)
  eq = eq or Defaults.eq
  for i = to, from, -1 do
    if eq(a[i], v) then
      return i
    end
  end
end

--- Extracts a range of elements of an array.
-- @tparam table a an array to extract the elements from.
-- @tparam integer from the starting index of the range to extract.
-- @tparam[optchain] integer to the ending index of the range to extract.
-- @treturn an array with the elements of the input array in the specified range.
function range(a, from, to)
  if #a == 0 then
    return {}
  end
  from, to = normalize(a, from, to)
  return tbl_move(a, from, to, 1, {})
end

-- Reverses in-place a range of elements of an array.
-- @tparam table a an array to reverse.
-- @tparam[opt] integer from the starting index of the range to reverse.
-- @tparam[optchain] integer to the ending index of the range to reverse.
function reverse(a, from, to)
  if #a == 0 then
    return a
  end
  from, to = normalize(a, from, to)
  while from < to do
    a[from], a[to] = a[to], a[from]
    from, to = from + 1, to - 1
  end
end

--- Shuffles in-place a range of elements of an array..
-- @tparam table a an array to shuffle.
-- @tparam[opt] integer from the starting index of the range to shuffle.
-- @tparam[optchain] integer to the ending index of the range to shuffle.
function shuffle(a, from, to)
  from, to = normalize(a, from, to)
  for i = to, from, -1 do
    local j = math_random(from, i)
    a[i], a[j] = a[j], a[i]
  end
end

--- Fills a range of an array with a specified value. If the value is `nil` the function
-- does nothing.
-- @tparam table a an array to fill.
-- @param v the value to use to fill the array.
-- @tparam[opt] integer from the starting index of the range to fill.
-- @tparam[optchain] integer to the ending index of the range to fill.
function fill(a, v, from, to)
  if v ~= nil then
    from, to = normalize(a, from, to)
    for i = from, to do
      a[i] = v
    end
  end
end

local function grow(a, n)
  local v = true
  if #a > 0 then
    v = a[#a]
  end
  while n > 0 do
    a[#a + 1] = v
    n = n - 1
  end
end

local function shrink(a, n)
  while n > 0 do
    a[#a] = nil
    n = n - 1
  end
end

--- Resize an array to the specified length extending.
-- If the new length is greater than the array length, the array will be extended by duplicating its last element, or
-- `true` if the array is empty.
-- @function resize
-- @tparam table a the array to be grown.
-- @tparam integer n the new length of the array.
function resize(a, n)
  if #a < n then
    grow(a, n - #a)
  elseif #a > n then
    shrink(a, #a - n)
  end
end

--- Removes all the elements of an array within a specified range.
-- @tparam table a an array to remove the elements from.
-- @tparam[opt] integer from the starting index of the range to remove.
-- @tparam[optchain] integer to the ending index of the range to remove.
function remove_at(a, from, to)
  if not to then
    tbl_remove(a, from)
    return
  end

  from, to = normalize(a, from, to)
  if from <= to then
    if to + 1 <= #a then
      tbl_move(a, to + 1, #a, from, a)
    end
    resize(a, #a - to + from - 1)
  end
end

-- Searches a range of elements of an array for the first occurrence of a
-- specified value using the specified equality comparer, and remove it.
-- @tparam table a an array to remove the value from.
-- @param v the element to be removed.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[optchain] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn boolean `true` if any element is removed, otherwise `false`.
function remove(a, v, from, to, eq)
  if #a == 0 then
    return false
  end
  from, to, eq = normalize(a, from, to, eq)
  eq = eq or Defaults.eq
  for i = from, to do
    if eq(a[i], v) then
      tbl_remove(a, i)
      return true
    end
  end
  return false
end

--- Searches a range of elements of an array for all the occurrences of the
-- specified value using a specified equality comparer, and remove them.
-- @tparam table a the array to remove the values from.
-- @param v the value to be removed.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam[opt] function eq the function used to the the values for equality (see @{eq_comparer}).
-- @treturn integer the number of elements removed.
function remove_all(a, v, from, to, eq)
  if #a == 0 then
    return 0
  end
  from, to, eq = normalize(a, from, to, eq)
  eq = eq or Defaults.eq
  local n = 0
  for i = to, from, -1 do
    if eq(a[i], v) then
      tbl_remove(a, i)
      n = n + 1
    end
  end
  return n
end

--- Searches a range of elements of an array for the first element satisfying a
-- specified condition, and remove it.
-- @tparam table a an array to be searched.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn boolean `true` if any element is removed, otherwise `false`.
function remove_if(a, from, to, p)
  if #a == 0 then
    return 0
  end

  from, to, p = normalize(a, from, to, p)
  for i = from, to do
    if p(a[i]) then
      tbl_remove(a, i)
      return true
    end
  end
  return false
end

--- Searches a range of elements of an array for all the elements satisfying a
-- specified condition, and remove them.
-- @tparam table a an array to be searched.
-- @tparam[opt] integer from the starting index of the range to search.
-- @tparam[optchain] integer to the ending index of the range to search.
-- @tparam function p a function to test each element (see @{predicate}).
-- @treturn integer the number of elements removed.
function remove_all_if(a, from, to, p)
  if #a == 0 then
    return 0
  end
  from, to, p = normalize(a, from, to, p)
  local n = 0
  for i = to, from, -1 do
    if p(a[i]) then
      tbl_remove(a, i)
      n = n + 1
    end
  end
  return n
end

--- Returns the string representation of a range of elements of an array.
-- @tparam table a an array.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @treturn string the string representing the specified range of elements.
function to_string(a, from, to)
  if #a == 0 then
    return '{}'
  end
  from, to = normalize(a, from, to)

  local b = {}
  local function add_value(v)
    if v == nil then
      b[#b + 1] = 'nil'
      return
    end
    local tv = type(v)
    if tv == 'string' then
      b[#b + 1] = stringx.smart_quotes(v)
    else
      b[#b + 1] = tostring(v)
    end
  end

  local sep = ', '
  b[#b + 1] = '{'
  if from > 1 then
    b[#b + 1] = '...'
    b[#b + 1] = sep
  end
  for i = from, to do
    add_value(a[i])
    b[#b + 1] = sep
  end
  if to < #a then
    b[#b + 1] = '...'
  end
  if b[#b] == sep then
    b[#b] = nil
  end
  b[#b + 1] = '}'

  return tbl_concat(b)
end

--- Invokes a function on each element of a range of elements of an array.
-- @tparam table a an array to invoke the function on.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @tparam function f a function to invoke on each element; the second
-- parameter is the index of the element in the array.
function each(a, from, to, f)
  from, to, f = normalize(a, from, to, f)
  for i = from, to do
    f(a[i], i)
  end
end

--- Returns an iterator over a specified range of elements of an array.
-- @tparam table a an array to return the iterator of.
-- @tparam[opt] integer from the starting index of the range.
-- @tparam[optchain] integer to the ending index of the range.
-- @treturn function an iterator.
function values(a, from, to)
  from, to = normalize(a, from, to)
  from = from - 1
  return function()
    if from < to then
      from = from + 1
      return a[from]
    end
  end
end

--- Inserts the values of an array at the given position in another array, shifting
-- its elements.
-- @tparam table src the array with the values to insert.
-- @tparam table dst the array to insert the values into.
-- @tparam[opt=#a1 + 1] integer pos the position at which to insert the new values.
function insert_all(src, dst, pos)
  if #src == 0 then
    return
  end
  if pos == nil then
    pos = #dst + 1
  end

  local n = #src
  if pos <= #dst then
    tbl_move(dst, pos, #dst, pos + n, dst)
  end
  tbl_move(src, 1, #src, pos, dst)
end

--- Inserts the values of an array at the given position in another array, shifting
-- its elements. If a predicated is specified, the source array is filtered using it.
-- @tparam table src the array with the values to insert.
-- @tparam table dst the array to insert the values into.
-- @tparam[opt=#a1 + 1] integer pos the position at which to insert the new values.
-- @tparam[opt] function p a function to test each element (see @{predicate}).
function insert_all_if(src, dst, pos, p)
  if type(pos) == 'function' then
    p, pos = pos, nil
  end
  if pos == nil then
    pos = #dst + 1
  end
  if #src == 0 then
    return
  end

  local n = #src - count(src, p)
  if pos <= #dst then
    tbl_move(dst, pos, #dst, pos + n, dst)
  end
  for i, v in ipairs(src) do
    if p(v, i) then
      dst[pos] = v
      pos = pos + 1
    end
  end
end

--- Inserts a specified value at the given position of a giving array, shifting
-- its elements.
-- @function insert
-- @tparam table a1 the array to insert the values into.
-- @tparam integer pos the position at which to insert the new values.
-- @tparam table a2 the array with the values to insert.
insert = tbl_insert

--- Function Types
-- @section fn_types

--- Tests an array element for a condition.
-- @function predicate
-- @param x the array element to be tested.
-- @tparam integer i the index of the array element.
-- @treturn boolean `true` if the element satisfies the condition, `false` otherwise.

--- Signature of a key selector function.
-- @function key_selector
-- @param x the array element.
-- @tparam integer i the element's index.
-- @return any value that can be used as a table key.

--- Compares two elements for equality.
-- @function eq_comparer
-- @param x the first element to compare.
-- @param y the second element to compare.
-- @treturn boolean `true` if the specified objects are equal; `false` otherwise.

--- Compares two elements and returns a value indicating whether one is less than,
-- equal to, or greater than the other.
-- @function comparer
-- @param x the first element to compare.
-- @param y the second element to compare.
-- @treturn int a signed integer that indicates the relative values of x and y,
-- as shown in the following table

return M
