---
-- @module std.version
local M = {}

local checks = require 'std.checks'

local setmetatable = setmetatable
local tonumber = tonumber
local type = type

local tbl_concat = table.concat

local _ENV = M

local Patterns = {
  '^(%d+)%.(%d+)%.(%d+)%.(%d+)$', --
  '^(%d+)%.(%d+)%.(%d+)$', --
  '^(%d+)%.(%d+)$'
}

local function match_patterns(s, patterns)
  for i = 1, #patterns do
    local major, minor, patch, build, revision = s:match(patterns[i])
    if major then
      return major, minor, patch, build, revision
    end
  end
end

local prototype = {}
local mt = {
  __type = 'version',
  __index = prototype,
  __tostring = function(self)
    local t = {self.major, self.minor}
    if self.patch ~= -1 then
      t[#t + 1] = self.patch
    end
    if self.build ~= -1 then
      t[#t + 1] = self.build
    end
    if self.revision ~= -1 then
      t[#t + 1] = self.revision
    end
    return tbl_concat(t, '.')
  end,
  __eq = function(x, y)
    return x:compare(y) == 0
  end,
  __lt = function(x, y)
    return x:compare(y) < 0
  end,
  __le = function(x, y)
    return x:compare(y) <= 0
  end
}

function parse(s)
  checks.check_type(1, 'string')
  local major, minor, patch, build, revision = match_patterns(s, Patterns)
  checks.check_arg(1, not not major, "Invalid version string")

  major = tonumber(major)
  minor = tonumber(minor)
  patch = patch and tonumber(patch) or -1
  build = build and tonumber(build) or -1
  revision = revision and tonumber(revision) or -1
  return new(major, minor, patch, build, revision)
end

function prototype:compare(y)
  checks.check_type(2, 'version|string')
  if type(y) == 'string' then
    y = parse(y)
  end
  if self.major > y.major then
    return 1
  elseif self.major < y.major then
    return -1
  elseif self.minor > y.minor then
    return 1
  elseif self.minor < y.minor then
    return -1
  elseif self.patch > y.patch then
    return 1
  elseif self.patch < y.patch then
    return -1
  elseif self.build > y.build then
    return 1
  elseif self.build < y.build then
    return -1
  elseif self.revision > y.revision then
    return 1
  elseif self.revision < y.revision then
    return -1
  else
    return 0
  end
end

function new(major, minor, patch, build, revision)
  checks.check_types('integer', 'integer', '?integer', '?integer', '?integer')
  patch = patch or 0
  build = build or 0
  revision = revision or 0

  return setmetatable({
    major = major, --
    minor = minor,
    patch = patch,
    build = build,
    revision = revision
  }, mt)
end

return M
