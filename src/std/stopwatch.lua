local M = {}

local time = require 'std.time'
local monotonic_ns = time.monotonic_ns

local setmetatable = setmetatable

local _ENV = M

local prototype = {}

function prototype:start()
  if self.running then return end
  self.start_time = monotonic_ns()
  self.running = true
end

function prototype:stop()
  if not self.running then return end
  local now = monotonic_ns()
  local dt = now - self.start_time
  self.elapsed = self.elapsed + dt
  self.running = false
end

function prototype:reset()
  self.elapsed = 0
  self.running = false
  self.start_time = 0
end

function prototype:restart()
  self.elapsed = 0
  self.running = true
  self.start_time = monotonic_ns()
end

function prototype:get_elapsed_time_ns()
  if not self.running then
    return self.elapsed
  end

  local now = monotonic_ns()
  local dt = now - self.start_time
  return self.elapsed + dt
end

function prototype:get_elapsed_time_ms()
  return self:get_elapsed_time_ns() / 1e6
end

function prototype:get_elapsed_time()
  return self:get_elapsed_time_ns() / 1e9
end

local mt = {
  __index = prototype,
  __tostring = function(self)
    return ('%d'):format(self:get_elapsed_time_ns())
  end
}

function start()
  local sw = setmetatable({
    running = false,
    start_time = 0,
    elapsed = 0
  }, mt)
  sw:start()
  return sw
end


return M
