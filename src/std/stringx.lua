--- Extensions to the `string` module.
-- @module std.stringx
local M = {}

local error = error
local ipairs = ipairs
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local type = type

local str_find = string.find
local tbl_concat = table.concat
local tbl_pack = table.pack
local tbl_unpack = table.unpack

local MAX_INT = math.maxinteger

local _ENV = M

local L_SPACE = '^%s*(.-)$'
local R_SPACE = '^(.-)%s*$'
local LR_SPACE = '^%s*(.-)%s*$'

local caches = setmetatable({}, {__mode = 'k'})
local function get_pattern(p, f)
  local cache = caches[f]
  if not cache then
    cache = setmetatable({}, {__mode = 'k'})
    caches[f] = cache
  end
  local r = cache[p]
  if not r then
    r = f(p)
    cache[p] = r
  end
  return r
end

--- Creates an array with the characters of a string.
-- @tparam string s a string to be divided into characters.
-- @tparam[opt] table a a table where to store the characters.
-- @treturn {string} an table with the characters of `s`.
function chars(s, a)
  a = a or {}
  for c in s:gmatch('.') do
    a[#a + 1] = c
  end
  return a
end

find = str_find

--- Searches a string for the last occurrence of the specified pattern.
-- @tparam string s the string to be searched.
-- @tparam string p the pattern to search for.
-- @tparam integer init the index  where to start the search.
-- @tparam[opt=`%s`] boolean plain if `true` the pattern is considered a plain string.
-- @treturn integer the index where the pattern starts.
-- @treturn integer the index where the pattern ends.
-- @return ... the captures of the pattern, if it contained any.
function find_last(s, p, init, plain)
  local r1 = tbl_pack(s:find(p, init, plain))
  if #r1 == 0 then
    return nil
  end
  while true do
    local r2 = tbl_pack(s:find(p, r1[2] + 1, plain))
    if #r2 == 0 then
      return tbl_unpack(r1)
    end
    r1 = r2
  end
end

--- Removes all the leading occurrences of a specified pattern from a string.
-- @tparam string s the string to be trimmed.
-- @tparam[opt=`%s`] string p the pattern to remove; the pattern must not contain
-- captures, and be a single character, or a character class: `'c'`, `'%a'`, `'[^%a]'`;
-- the function behavior is undefined for any other type of pattern.
-- @treturn string the string that remains after all the leading occurrences
-- of the specified pattern are removed from the input string.
function trim_left(s, p)
  p = p and get_pattern(p, function(x)
    return ('^%s(.-)$'):format(x)
  end) or L_SPACE
  local t = s:match(p)
  while t and t ~= s do
    s, t = t, t:match(p)
  end
  return s
end

--- Removes all the trailing occurrences of a specified pattern from a string.
-- @tparam string s the string to be trimmed.
-- @tparam[opt=`%s`] string p the pattern to remove; the pattern must not contain
-- captures, and be a single character, or a character class: `'c'`, `'%a'`, `'[^%a]'`;
-- the function behavior is undefined for any other type of pattern.
-- @treturn string the string that remains after all the trailing occurrences
-- of the specified pattern are removed from the input string.
function trim_right(s, p)
  p = p and get_pattern(p, function(x)
    return ('^(.-)%s$'):format(x)
  end) or R_SPACE
  local t = s:match(p)
  while t and t ~= s do
    s, t = t, t:match(p)
  end
  return s
end

--- Removes all the leading and trailing occurrences of a specified pattern
-- from a string.
-- @tparam string s the string to be trimmed.
-- @tparam[opt=`%s`] string p the pattern to remove; the pattern must not contain
-- captures, and be a single character, or a character class: `'c'`, `'%a'`, `'[^%a]'`;
-- the function behavior is undefined for any other type of pattern.
-- @treturn string the string that remains after all the leading and trailing
-- occurrences of the specified pattern are removed from the input string.
function trim(s, p)
  p = p and get_pattern(p, function(x)
    return ('^%s(.-)%s$'):format(x, x)
  end) or LR_SPACE
  local t = s:match(p)
  while t and t ~= s do
    s, t = t, t:match(p)
  end
  return s
end

--- Splits a string into multiple strings based on a specified separator.
-- @tparam string s the string to be split.
-- @tparam[opt=`%s`] string sep the pattern to remove; the pattern must not contain
-- captures, and be a single character, or a character class: `'c'`, `'%a'`, `'[^%a]'`;
-- the function behavior is undefined for any other type of pattern.
-- @tparam[optchain] boolean empty whether to include empty strings.
-- @tparam[optchain] integer max_count the maximum number of substrings to return.
-- @treturn {string} an array containing the substrings in the input string that
-- are delimited by one or more separators.
function split(s, sep, empty, max_count)
  sep = sep or '%s'
  if type(empty) == 'number' then
    max_count, empty = empty, false
  end

  local r = {}
  local i = 1
  while true do
    local j = s:find(sep, i)
    if not j then
      break
    end
    if j ~= i then
      r[#r + 1] = s:sub(i, j - 1)
    elseif empty then
      r[#r + 1] = ''
    end
    i = j + 1
    if max_count and #r == max_count then
      return r
    end
  end
  r[#r + 1] = i == 1 and s or s:sub(i)
  return r
end

--- Determines whether a string begins with a specified pattern.
-- @tparam string s the string to be tested.
-- @tparam string p the pattern to search for; the pattern must not contain
-- neither captures nor anchors.
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn boolean `true` if the pattern is found at the beginning of the
-- input string.
function starts_with(s, p, plain)
  if plain then
    return s:find(p, 1, true) == 1
  end
  p = get_pattern(p, function(x)
    return ('^%s'):format(x)
  end)
  return s:find(p) ~= nil
end

--- Determines whether a string ends with a specified pattern.
-- @tparam string s the string to be tested.
-- @tparam string p the pattern to search for; the pattern must not contain
-- neither captures nor anchors.
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn boolean `true` if the pattern is found at the end of the
-- input string.
function ends_with(s, p, plain)
  if plain then
    local _, e = s:find(p, #s - #p, true)
    return e == #s
  end
  p = get_pattern(p, function(x)
    return ('%s$'):format(x)
  end)
  return s:find(p) ~= nil
end

--- Searches `sep` in the string `s` from the beginning of the string and returns
-- the part before it, the match, and the part after it. If it is not found,
-- returns two empty strings and `s`.
-- @tparam string s the string to be searched.
-- @tparam string sep the pattern to search
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn string the substring occurring before the specified pattern.
-- @treturn string the substring matching the specified pattern.
-- @treturn string the substring occurring after the specified pattern.
function partition(s, sep, plain)
  local ps, pe = s:find(sep, 1, plain)
  if not ps then
    return s, nil, nil
  end
  return s:sub(1, ps - 1), s:sub(ps, pe), s:sub(pe + 1)
end

--- Searches `sep` in the string `s` from the end of the string and returns
-- the part before it, the match, and the part after it. If it is not found,
-- returns two empty strings and `s`.
-- @tparam string s the string.
-- @tparam string sep the separator.
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn string the part before the separator.
-- @treturn string the separator
-- @treturn string the part after the separator.
function partition_right(s, sep, plain)
  local ps, pe = find_last(s, sep, 1, plain)
  if not ps then
    return nil, nil, s
  end
  return s:sub(1, ps - 1), s:sub(ps, pe), s:sub(pe + 1)
end

--- Returns a new string with characters in `from` replaced with the
-- corresponding characters in `to`.
-- Characters in `from` that do not have a correspondent character in `to` are removed.
-- @tparam string s the string.
-- @tparam string from the characters to replace.
-- @tparam string to the replacement characters.
-- @treturn string the new string.
function translate(s, from, to)
  if s == nil or #s == 0 then
    return s
  end

  local m
  return (s:gsub('(.)', function(c)
    local i = from:find(c)
    if not i then
      return c
    end
    if not m then
      m = chars(to)
    end
    return m[i] or ''
  end))
end

--- Shorthand for `translate`.
-- @see translate
-- @function tr
-- @tparam string s the string.
-- @tparam string from the characters to replace.
-- @tparam string to the replacement characters.
-- @treturn string the new string.
tr = translate

--- Simple string interpolator; it inserts its arguments between corresponding
-- parts of a pattern.
-- @tparam string s a pattern to interpolate.
-- @tparam table values the arguments to be replaced.
-- @treturn string the formatted string.
--
-- @usage
-- print(S("Hello, $name", {name = 'James'})))
function S(s, values)
  return (s:gsub('%$([^%$%s]+)', function(w)
    return tostring(values[tonumber(w) or w])
  end))
end

--- The formatted string interpolator; it inserts its arguments between
-- corresponding parts of the pattern.
-- @tparam string s a pattern to interpolate.
-- @tparam table values the arguments to be replaced.
-- @treturn string the formatted string.
--
-- @usage
-- print(F("$height%2.2f", {height = 1.9}))
function F(s, values)
  return (s:gsub('%$([^%$%s]+)(%%%S+)', function(w, fmt)
    return fmt:format(values[tonumber(w) or w])
  end))
end

--- Returns a copy of `s' with all characters in `x` deleted.
-- @tparam string s the string.
-- @tparam string p the pattern representing the characters to delete.
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn string the new string with the characters deleted.
function delete(s, p, plain)
  if plain then
    for _, c in ipairs(chars(p)) do
      s = s:gsub(c, '')
    end
  else
    s = s:gsub(p, '')
  end
  return s
end

--- Returns the string `s` with all the runs of the characters in `x`
-- replaced with a single character.
-- @tparam string s the string.
-- @tparam string p the pattern representing the characters to squeeze.
-- @tparam[opt] boolean plain if `true` the pattern is considered a plain string.
-- @treturn string the new string.
function squeeze(s, p, plain)
  local t, lc = {}, nil
  if plain then
    p = ('[%s]'):format(p)
  end
  for c in s:gmatch('.') do
    if c ~= lc then
      t[#t + 1] = c
      if c:match(p) then
        lc = c
      else
        lc = nil
      end
    end
  end
  return tbl_concat(t)
end

--- Inserts `x` before the character at the given `position` in `s`.
-- @tparam string s the string.
-- @tparam string x the string to insert
-- @tparam[opt] integer position the position to insert the string at; it must
-- be a valid index.
-- @treturn string the new string; or `s` if the index is not valid.
function insert(s, x, position)
  if #x == 0 or position == 0 then
    return s
  end
  if not position then
    return ('%s%s'):format(x, s)
  elseif position == 1 then
    return ('%s%s'):format(x, s)
  elseif position == -1 then
    return ('%s%s'):format(s, x)
  elseif position > 0 then
    return ('%s%s%s'):format(s:sub(1, position - 1), x, s:sub(position))
  end
  return ('%s%s%s'):format(s:sub(1, position - 1), x, s:sub(position))
end

--- Returns an array containing the string `s` split into lines.
-- @tparam string s the string.
-- @tparam[opt] integer max_count the maximum number of lines to return.
-- @treturn {string} an array whose elements contains the lines of `s`.
function lines(s, max_count)
  local a = {}
  each_line(s, max_count, function(line)
    a[#a + 1] = line
  end)
  return a
end

--- Splits the string `s` into lines and invoke `f` with each of them.
-- @tparam string s the string.
-- @tparam[opt] integer max_count the maximum number of lines to process.
-- @tparam consumer f the function to invoke.
function each_line(s, max_count, f)
  if type(max_count) == 'function' then
    f, max_count = max_count, nil
  end
  each(s, '\n\r', max_count, f)
end

--- Splits the string `s` into substring divided by the given separator `sep`
-- and invoke `f` with each of them.
-- @tparam string s the string.
-- @tparam[opt=' '] string sep the separator.
-- @tparam[optchain] integer max_count the maximum number of strings to process.
-- @tparam consumer f the function to invoke.
function each(s, sep, max_count, f)
  if type(sep) == 'function' then
    f, sep, max_count = sep, ' ', MAX_INT
  elseif type(max_count) == 'function' then
    f, max_count = max_count, MAX_INT
  end
  sep = sep or ' '
  max_count = max_count or MAX_INT
  if max_count < 1 then
    return
  end
  local wp = ('([^%s]+)'):format(sep)
  local itr = s:gmatch(wp)
  local w = itr()
  while w and max_count > 0 do
    f(w)
    w, max_count = itr(), max_count - 1
  end
end

--- Centers a string on a specified width.
-- If the specified width is greater than the input string's length, returns a
-- new string padded with the specified character; otherwise it returns the input string
-- unchanged.
-- @tparam string s the string to be centered.
-- @tparam integer width the width of the line to center the line on.
-- @tparam[opt=' '] string pad the character to use for padding.
-- @treturn string the input string centered on a line of the specified width.
function center(s, width, pad)
  pad = pad or ' '
  if #s > width then
    return s
  end
  local margin = (width - #s) // 2
  local r, q = margin % #pad, margin // #pad

  local buf, i = {}, 1
  buf[i], i = pad:rep(q), i + 1
  if r > 0 then
    buf[i], i = pad:sub(1, r), i + 1
  end
  buf[i], i = s, i + 1

  margin = width - #s - margin
  r, q = margin % #pad, margin // #pad
  buf[i], i = pad:rep(q), i + 1
  if r > 0 then
    buf[i] = pad:sub(1, r)
  end

  return tbl_concat(buf)
end

--- Expands the tabs in a given string into spaces.
-- @tparam string s the string whose tabs will be expanded.
-- @tparam[opt=8] integer tab_size the size in spaces of each tab.
-- @treturn string the input string with the tabs replaces by the specified number of spaces.
function expand_tabs(s, tab_size)
  tab_size = tab_size or 8
  return (s:gsub('\t', (' '):rep(tab_size)))
end

--- Returns a left-justified string of the specified length by padding a given
-- string with the specified padding characters.
-- @tparam string s the string to be left-justified.
-- @tparam integer width the width of the line to left-justify the line on.
-- @tparam[opt=' '] string pad the character to use for padding.
-- @treturn string the input string left-justified on a line of the specified width.
function justify_left(s, width, pad)
  pad = pad or ' '
  if #s >= width then
    return s
  end
  local margin = width - #s
  local r, q = margin % #pad, margin // #pad

  local buf, i = {}, 1
  buf[i], i = s, i + 1
  buf[i], i = pad:rep(q), i + 1
  if r > 0 then
    buf[i], i = pad:sub(1, r), i + 1
  end
  buf[i] = nil
  return tbl_concat(buf)
end

--- Returns a right-justified string of the specified length by padding a given
-- string with the specified padding characters.
-- @tparam string s the string to be right-justified.
-- @tparam integer width the width of the line to right-justify the line on.
-- @tparam[opt] string pad the character to use for padding.
-- @treturn string the input string right-justified on a line of the specified width.
function justify_right(s, width, pad)
  pad = pad or ' '
  if #s >= width then
    return s
  end
  local margin = width - #s
  local r, q = margin % #pad, margin // #pad

  local buf, i = {}, 1
  buf[i], i = pad:rep(q), i + 1
  if r > 0 then
    buf[i], i = pad:sub(1, r), i + 1
  end
  buf[i], i = s, i + 1
  buf[i] = nil
  return tbl_concat(buf)
end

--- Wraps a given string to the specified width.
-- @tparam string s the string to be wrapped.
-- @tparam integer width the width the line is wrapped to.
-- @treturn string the input string wrapped to the specified width.
function wrap(s, width)
  if #s < width then
    return s
  end
  local buf, i, len, spc = {}, 1, 0, nil
  local function append(x, is_space)
    if i > 1 and len > 0 and len + #x > width then
      buf[i], i = '\n', i + 1
      len = 0
      if is_space then
        return
      end
    end
    if is_space then
      spc = x
    else
      if spc and len > 0 then
        buf[i], i = spc, i + 1
        spc = nil
      end
      buf[i], i = x, i + 1
    end
    len = len + #x
  end

  local le = 1
  for b, w, e in s:gmatch('()(%S+)()') do
    if b > le then
      append(s:sub(le, b - 1), true)
    end
    append(w)
    le = e
  end
  buf[i] = nil
  return tbl_concat(buf)
end

local function arg_error(i, name, msg, level)
  if type(msg) == 'number' then
    level, msg = msg, nil
  end
  level = level or 1
  if msg then
    msg = ("bad argument #%d to '%s' (%s)"):format(i, name, msg)
  else
    msg = ("bad argument #%d to '%s'"):format(i, name)
  end
  error(msg, level + 2)
end

--- Replaces a format specifiers in a given string with the string representation of a
-- corresponding value; the function behaves like Lua's `string.format` but
-- also support positional specifiers: `%n$...`.
-- @tparam string s a format string.
-- @param ... the values to be formatted.
-- @treturn string a copy of `s` in which the format items have been replaced
-- by the string representation of the corresponding value.
-- @raise if positional and non positional format specifiers are used together.
function format(s, ...)
  local args = tbl_pack(...)
  local ss, i, p = s, 0, nil
  local b = {}
  repeat
    local h, n, fmt, t = ss:match('^(.-)%%(%d*)%$?([^%%]+)(.*)$')
    if #n > 0 then
      p, i = true, p == false and arg_error(1, 'format', "invalid format") or tonumber(n)
    else
      p, i = false, p == true and arg_error(1, 'format', "invalid format") or i + 1
    end
    b[#b + 1] = #h > 0 and h or nil
    b[#b + 1] = ('%' .. fmt):format(args[i])
    ss = t
  until #ss == 0
  return tbl_concat(b)
end

local EscapeSequences = {
  ['\a'] = '\\a',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
  ['\v'] = '\\v',
  ['\\'] = '\\\\'
}
local UnescapeSequences = {
  ['\\a'] = '\a',
  ['\\b'] = '\b',
  ['\\f'] = '\f',
  ['\\n'] = '\n',
  ['\\r'] = '\r',
  ['\\t'] = '\t',
  ['\\v'] = '\v',
  ['\\\\'] = '\\'
}

--- Escapes a minimal set of control codes by replacing them with their escape codes.
-- @tparam string s the string to escape.
-- @treturn string the escaped string.
function escape(s)
  return (s:gsub('.', EscapeSequences))
end

--- Converts any escaped characters in a given string.
-- @tparam string s the string to convert.
-- @treturn string a string with any escaped characters converted to their unescaped value.
function unescape(s)
  return (s:gsub('\\.', UnescapeSequences))
end

--- Wraps a given string in the appropriate pair of quote characters.
-- @tparam string s the string to wrap.
-- @treturn string the input string wrapped in quote characters.
function smart_quotes(s)
  local has_single = s:find("'", 1, true)
  local has_double = s:find('"', 1, true)
  if has_single and has_double then
    return ('[[%s]]'):format(s)
  elseif has_single then
    return ('"%s"'):format(s)
  end
  return ("'%s'"):format(s)
end

--- Function Types
-- @section fn_types

--- signature of a @{each} or @{each_line} callback function
-- @function consumer
-- @tparam string s a string
-- @see each
-- @see each_line

return M
