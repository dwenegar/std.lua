--- Provides functions for manipulating text.
-- @module std.text
local M = {}

local math_floor = math.floor

local _ENV = M

--- Centers a string on a specified width.
--
-- If the specified width is greater than the input string's length, returns a
-- new string padded with the specified character; otherwise it returns the input string
-- unchanged.
--
-- @tparam string text the text to be centered.
-- @tparam[opt=80] integer width the width of the line to center the line on.
-- @tparam[optchain=' '] string pad the character to use for padding.
-- @treturn string the input string centered on a line of the specified width.
function center(text, width, pad)
  if width == nil or width < 0 then
    width = 80
  end
  pad = pad and pad:sub(1, 1) or ' '
  if #text > width then
    return text
  end
  local left_margin = math_floor((width - #text) / 2)
  local right_margin = width - #text - left_margin
  return ('%s%s%s'):format(pad:rep(left_margin), text, pad:rep(right_margin))
end

--- Expands the tabs in a given string into spaces.
-- @tparam string text the text whose tabs will be expanded.
-- @tparam[opt=8] integer tab_size the size in spaces of each tab.
-- @treturn string the input string with the tabs replaces by the specified number of spaces.
function expand_tabs(text, tab_size)
  tab_size = tab_size or 8
  return (text:gsub('\t', (' '):rep(tab_size)))
end

--- Left-justifies a given string on a string of the specified width.
-- @tparam string text the text to be left-justified.
-- @tparam[opt=80] integer width the width of the line to left-justify the line on.
-- @tparam[optchain=' '] string pad the character to use for padding.
-- @treturn string the input string left-justified on a line of the specified width.
function right_pad(text, width, pad)
  width = width or 80
  pad = pad or ' '
  if #text >= width then
    return text
  end
  return ('%s%s'):format(text, pad:rep(width - #text))
end

--- Right-justifies a given string on a string of the specified width.
-- @tparam string text the text to be right-justified.
-- @tparam[opt=80] integer width the width of the line to right-justify the line on.
-- @tparam[optchain=' '] string pad the character to use for padding.
-- @treturn string the input string right-justified on a line of the specified width.
function left_pad(text, width, pad)
  width = width or 80
  pad = pad or ' '
  if #text >= width then
    return text
  end
  return ('%s%s'):format(pad:rep(width - #text), text)
end

--- Wraps a given string to the specified width.
-- @tparam string text the text to be wrapped. function
-- @tparam[opt=80] integer width the width the line is wrapped to.
-- @treturn string the input string wrapped to the specified width.
function wrap(text, width)
  width = width or 80
  if #text < width then
    return { text }
  end
  local lines = {}
  for line in text:gmatch('([^\n\r]+)') do
    line = line:match('^%s*(.*)%s*$')
    if #line < width then
      lines[#lines + 1] = line
    else
      local i, j, ns = 1, 0, 1
      local s, e
      repeat
        s = ns
        while i and i - s <= width do
          e, ns = i - 1, j + 1
          i, j = line:find('%s+', ns)
        end
        if e < s and i then
          e, ns = i - 1, j + 1
        end
        lines[#lines + 1] = line:sub(s, e)
      until not i
      end
  end
  return lines
end

return M
