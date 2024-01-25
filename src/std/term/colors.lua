---
-- @module std.term.colors

local M = {}

local error = error
local pairs = pairs
local concat = table.concat
local tostring = tostring

_ENV = M

local escapes = {}
do
  local codes = {
    -- reset
    reset = 0,

    -- styles
    bold = 1,
    dim = 2,
    italic = 3,
    underline = 4,
    blink = 5,
    reverse = 7,
    hidden = 8,
    crossed = 9,

    -- text color (foreground)
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    bright_black = 90,
    bright_red = 91,
    bright_green = 92,
    bright_yellow = 93,
    bright_blue = 94,
    bright_magenta = 95,
    bright_cyan = 96,
    bright_white = 97,

    -- text color (background)
    black_bg = 40,
    red_bg = 41,
    green_bg = 42,
    yellow_bg = 43,
    blue_bg = 44,
    magenta_bg = 45,
    cyan_bg = 46,
    white_bg = 47,
    bright_black_bg = 100,
    bright_red_bg = 101,
    bright_green_bg = 102,
    bright_yellow_bg = 103,
    bright_blue_bg = 104,
    bright_magenta_bg = 105,
    bright_cyan_bg = 106,
    bright_white_bg = 107,
  }
  for name, value in pairs(codes) do
    escapes[name] = ('\27[%dm'):format(value)
    M[name] = function(text)
      return ('%s%s%s'):format(escapes[name], tostring(text), escapes.reset)
    end
  end
end

local function replace(codes)
  local buffer = {}
  for code in codes:gmatch('%w+') do
    local escape = escapes[code]
    if not escape then
      error(('%q: unknown ansi code'):format(code), 2)
    end
    buffer[#buffer + 1] = escape
  end
  return concat(buffer)
end

local function expand(_, s)
  local codes, text = s:match('^([%a,]*):(.*)$')
  if text then
    return ('%s%s%s'):format(replace(codes), text, escapes.reset)
  end
  return replace(s)
end

--- Colorizes the input string.
-- @param s the string to colorize
-- @return the given string with the color markups replaced by console's escape codes.
function colorize(s)
  local colorized, _ = s:gsub('(#{(.-)})', expand)
  return colorized
end

--- Colorizes the input string
-- @param s a format string
-- @param ... arguments to be substituted in the string
-- @return the given string with the color markups replaced by console's escape codes.
function colorizef(s, ...)
  return colorize(s:format(...))
end

return M
