--- Provides methods for converting string to base64 and base2.
-- @module std.convert

local M = {}

local array = require 'std.array'

local assert = assert
local str_byte = string.byte
local tbl_insert = table.insert
local tbl_concat = table.concat

local _ENV = M

local function str_to_bits(str, stride)
  local bits = {}
  for c in str:gmatch('.') do
    local byte = str_byte(c)
    for i = #bits + 8, #bits + 1, -1 do
      bits[i] = byte % 2
      byte = byte // 2
    end
  end

  while #bits % stride > 0 do
    tbl_insert(bits, 0)
  end

  return bits
end

local function bits_to_number(bits)
  local n = 0
  for i = 1, #bits do
    n = n * 2 + bits[i]
  end
  return n
end

local function to_base(str, stride, digits, pad)

  local bits = str_to_bits(str, stride)
  assert(#bits % stride == 0)

  local r = {}
  local chunk = {}
  for i = 1, #bits, stride do
    array.copy(bits, i, i + stride - 1, chunk)
    local digit = bits_to_number(chunk)
    tbl_insert(r, digits[digit + 1])
  end

  if pad then
    tbl_insert(r, pad)
  end

  return tbl_concat(r)
end

local BASE64_PAD = {'', '==', '='}
local BASE64_ALPHABET = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
  'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
  't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
  '8', '9', '+', '/'
}

--- Convert the given string to base64
-- @tparam string str the string to convert.
-- @treturn string the input string converted to base64.
function to_base64(str)
  return to_base(str, 6, BASE64_ALPHABET, BASE64_PAD[#str % 3 + 1])
end

local BASE2_ALPHABET = {'0', '1'}

--- Convert the given string to base2.
-- @tparam string str the string to convert.
-- @treturn string the input string converted to binary.
function to_bits(str)
  return to_base(str, 1, BASE2_ALPHABET)
end

return M
