---
-- @module std.term.pager

local M = {}

local array = require 'std.array'

local ipairs = ipairs
local tostring = tostring

local tbl_concat = table.concat
local io_stdout = io.stdout

_ENV = M

local PADDING = 2
local INDENT = '  '

local function layout(list, opts)

  local width = opts.width
  local column_layout = opts.column_layout
  local padding = opts.padding or PADDING
  local indent = opts.indent or INDENT

  local col_width = 0
  for _, x in ipairs(list) do
    if #x > col_width then
      col_width = #x
    end
  end
  col_width = col_width + padding
  local cols = (width - #indent) // col_width
  if cols == 0 then
    cols = 1
  end
  return {
    padding = padding,
    indent = indent,
    cols = cols,
    rows = (#list + cols - 1) // cols,
    width = width,
    col_width = col_width,
    empty = (' '):rep(col_width),
    column_layout = column_layout
  }
end

local function to_index(row, col, config)
  if config.column_layout then
    return (col - 1) * config.rows + row
  end
  return (row - 1) * config.cols + col
end

local function layout_cell(buf, pos, list, row, col, config)
  local i = to_index(row, col, config)
  if i > #list then
    return true, pos
  end

  local function append(x)
    pos = pos + 1
    buf[pos] = x
  end

  local data = list[i]
  local padding = config.col_width - #data
  if col == 1 then
    append(config.indent)
  end
  append(data)

  local is_last
  if config.column_layout then
    is_last = i + config.rows > #list
  else
    is_last = col == config.cols or i == #list
  end

  if not is_last then
    append(config.empty:sub(1, padding))
  end
  return is_last, pos
end

---
function layout_table(list, opts)
  list = array.map(list, tostring)
  local config = layout(list, opts)
  local buf, row_buf = {}, {}
  for r = 1, config.rows do
    local pos = 0
    local done
    for c = 1, config.cols do
      done, pos = layout_cell(row_buf, pos, list, r, c, config)
      if done then
        buf[r] = tbl_concat(row_buf, '', 1, pos)
        break
      end
    end
  end
  return buf
end

---
function print_table(list, opts)
  local lines = layout_table(list, opts)
  for _, line in ipairs(lines) do
    io_stdout:write(line)
    io_stdout:write('\n')
  end
end

---
function layout_list(list, opts)
  list = array.map(list, tostring)

  local width = opts.width
  local indent = opts.indent or INDENT

  local buf, row_buf, len, pos = {}, {}, 0, 0
  local function append(x)
    pos = pos + 1
    row_buf[pos] = x
    len = len + #x
  end

  for i, data in ipairs(list) do
    if len + #data + 1 > width then
      buf[#buf + 1] = tbl_concat(row_buf, '', 1, pos)
      len, pos = 0, 0
    end
    if pos == 0 then
      append(indent)
    end
    append(data )
    if i < #list then
      append(', ')
    end
  end
  if pos > 0 then
    buf[#buf + 1] = tbl_concat(row_buf, '', 1, pos)
  end
  return buf
end

---
function print_list(list, opts)
  local lines = layout_list(list, opts)
  for _, line in ipairs(lines) do
    io_stdout:write(line)
    io_stdout:write('\n')
  end
end

--- Prints a given list using the specified options
-- @tparam array list the list to print
-- @tparam table opts the options to use when printing `list`
function print_plain(list, opts)
  local indent = INDENT
  if opts and opts.indent then
    indent = opts.indent
  end
  for _, x in ipairs(list) do
    io_stdout:write(indent)
    io_stdout:write(tostring(x))
    io_stdout:write('\n')
  end
end

return M
