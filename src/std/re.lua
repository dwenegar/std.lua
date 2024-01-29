local M = {}

local load = load
local tbl_pack = table.pack
local tbl_concat = table.concat

local _ENV = M

function any_of(...)
  local patterns = tbl_pack(...)
  local body = {}
  body[#body + 1] = 'local w = ...'
  body[#body + 1] = ('if w:match(%q) then return true'):format(patterns[1])
  for i = 2, #patterns do
    body[#body + 1] = ('elseif w:match(%q) then return true'):format(patterns[i])
  end
  body[#body + 1] = 'else return false end'
  body = tbl_concat(body, ' ')
  return load(body)
end

return M
