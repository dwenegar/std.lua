local debugx = require 'std.debugx'

describe('#debugx', function()
  describe('setfenv', function()
    it('should set the environment of the given function', function()
      local function f(v) x = v; return v end
      local env = {}
      assert.is_true(debugx.setfenv(f, env))
      assert.are_equal(f(10), env.x)
    end)
    it('should fail to set the environment of a C function', function()
      local env = {}
      assert.is_false(debugx.setfenv(print, env))
    end)
    it('it should report bad arguments', function()
      assert.error(function()
        local env = {}
        debugx.setfenv('not a function', env)
      end)
    end)
  end)
  describe('getfenv', function()
    local function f(v) x = v; return v end
    it('should get the function environment', function()
      local env = debugx.getfenv(f)
      assert.are_equal(f(10), env.x)
    end)
  end)
end)
