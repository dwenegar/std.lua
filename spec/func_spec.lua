local func = require 'std.func'

describe("#func", function()
  describe("compose", function()
    it("should return the proper result", function()
      local function f(x) return x + 1 end
      local function g(x) return x * 10 end
      local fg = func.compose(f, g)
      assert.are_equal(11, fg(1))
      assert.are_equal(101, fg(10))
    end)

    it("should handle function returning multiple values", function()
      local function f(x, y) return x + y end
      local function g(x) return x * 10, x end
      local fg = func.compose(f, g)
      assert.are_equal(11, fg(1))
    end)
  end)

  describe("partial", function()
    it("should return the proper result", function()
      local f = function(x, y) return x + y end
      local f1 = func.partial(1, f)
      assert.are_equal(2, f1(1))
      assert.are_equal(10, f1(9))
    end)
  end)

  describe("curry", function()
    it("should return the proper result", function()
      local f = function(x, y) return x + y end
      local curried = func.curry(f)
      assert.are_equal(2, curried(1)(1))
      assert.are_equal(10, curried(9)(1))
    end)
  end)

  local function test_memoize(n, memoize, f, ...)
    for _ = 1, n do
      local call_count = 0
      local mf = memoize(function(...)
        call_count = call_count + 1
        return f(...)
      end)
      assert.are_equal(0, call_count)
      local fa, fb = f(...)
      local mfa, mfb = mf(...)
      assert.are_equal(fa, mfa)
      assert.are_equal(fb, mfb)
      assert.are_equal(1, call_count)
      mf(...)
      assert.are_equal(1, call_count)
    end
  end

  describe("memoize0", function()
    it("should cache the function result", function()
      test_memoize(5, func.memoize0, function()
        return true
      end)
      test_memoize(5, func.memoize0, function()
        return true, 'true'
      end)
      test_memoize(5, func.memoize0, function()
        return nil, true
      end)
    end)
  end)
  describe("memoize1", function()
    it("should cache the function execution", function()
      test_memoize(5, func.memoize1, function(x)
        return x == nil
      end)
      test_memoize(5, func.memoize1, function(x)
        return x
      end, 1)
      test_memoize(5, func.memoize1, function(x)
        return x, x + 1
      end, 1)
      test_memoize(5, func.memoize1, function(x)
        return nil, x * x
      end, 1)
    end)
  end)
  describe("memoize2", function()
    it("should cache the function execution", function()
      test_memoize(5, func.memoize2, function(x1, x2)
        return x1 == nil and x2 == nil
      end)
      test_memoize(5, func.memoize2, function(x1, x2)
        return x1 + x2
      end, 7, 13)
      test_memoize(5, func.memoize2, function(x1, x2)
        return x1, x2
      end, 7, 15)
      test_memoize(5, func.memoize2, function(x1, x2)
        return nil, x1 * x2
      end, 7, 13)
    end)
  end)
  describe("memoize3", function()
    it("should cache the function execution", function()
      test_memoize(5, func.memoize3, function(x1, x2, x3)
        return x1 == nil and x2 == nil and x3 == nil
      end)
      test_memoize(5, func.memoize3, function(x1, x2, x3)
        return x1 + x2, x3
      end, 17, 13, 29)
      test_memoize(5, func.memoize3, function(x1, x2, x3)
        return x1, x2 + x3
      end, 7, 15, 29)
      test_memoize(5, func.memoize3, function(x1, x2, x3)
        return nil, x1 * x2 * x3
      end, 7, 17, 31)
    end)
  end)
  describe("memoize4", function()
    it("should cache the function execution", function()
      test_memoize(5, func.memoize4, function(x1, x2, x3, x4)
        return x1 == nil and x2 == nil and x3 == nil and x4 == nil
      end)
      test_memoize(5, func.memoize4, function(x1, x2, x3, x4)
        return x1 + x2, x3 + x4
      end, 17, 13, 29, 37)
      test_memoize(5, func.memoize4, function(x1, x2, x3, x4)
        return x1, x2 + x3 + x4
      end, 7, 15, 29, 31)
      test_memoize(5, func.memoize4, function(x1, x2, x3, x4)
        return nil, x1 * x2 * x3 / x4
      end, 7, 17, 31, 29)
    end)
  end)

  describe("always", function()
    it("should always return the same value", function()
      local one = func.always(1)
      assert.are_equal(1, one())
      assert.are_equal(1, one())
    end)
  end)

  describe("identity", function()
    it("should return the input value", function()
      for i = 1, 100 do
        assert.are_equal(i, func.identity(i))
      end
    end)
  end)

  describe("lambda", function()
    it("should report bad arguments", function()
      assert.error(function() func.lambda() end)
      local _, err = func.lambda("(")
      assert.is_not_nil(err)
      _, err = func.lambda("()")
      assert.is_not_nil(err)
      _, err = func.lambda("() => ")
      assert.is_not_nil(err)
      _, err = func.lambda("() => +")
      assert.is_not_nil(err)
    end)

    it("should compile a string into a simple function", function()
      local one, err = func.lambda('() => 1')
      assert.is_nil(err)
      assert.are_equal(1, one())

      -- repeat to hit the cache
      one, err = func.lambda('() => 1')
      assert.is_nil(err)
      assert.are_equal(1, one())
    end)

    it("should compile a string into a simple function", function()
      local sum2, err = func.lambda('(x,y) => x + y')
      assert.is_nil(err)
      assert.are_equal(1, sum2(1, 0))
      assert.are_equal(5, sum2(2, 3))
    end)

    it("should compile a string into a simple function", function()
      local pack = func.lambda('(x,y) => {y,x}')
      assert.same({0, 1}, pack(1, 0))
      assert.same({3, 2}, pack(2, 3))
    end)
  end)
end)
