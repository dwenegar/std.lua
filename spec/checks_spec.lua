-- luacheck: ignore 212

local checks = require 'std.checks'

describe("#checks", function()
  local function blame(f)
    local code = [[
      local function f(_) checks.%s end        -- 1
      local function g() f() end               -- 2
      local _, err = pcall(function() g() end) -- 3
      return err                               -- 4
    ]]
    return (load(code:format(f), 'caller', 'table', {checks = checks, pcall = pcall}))()
  end
  describe("arg_error", function()
    local function arg_error(...)
      local args = table.pack(...)
      return function()
        checks.arg_error(table.unpack(args))
      end
    end
    describe("bad arguments", function()
      it("diagnoses bad argument #1", function()
        assert.error(arg_error(), "bad argument #1 to 'arg_error' (number expected, got no value)")
        assert.error(arg_error('not a number'), "bad argument #1 to 'arg_error' (number expected, got string)")
        assert.error(arg_error(1.337), "bad argument #1 to 'arg_error' (number has no integer representation)")
      end)
      it("diagnoses bad argument #2", function()
        assert.error(arg_error(1, {}), "bad argument #2 to 'arg_error' (string expected, got table)")
        assert.error(arg_error(1, false), "bad argument #2 to 'arg_error' (string expected, got boolean)")
      end)
    end)
    describe("raising errors", function()
      global_fn = function(arg, message)
        checks.arg_error(arg, message)
      end
      local local_fn = function(arg, message)
        checks.arg_error(arg, message)
      end
      it("reports the correct function name", function()
        assert.error(function() global_fn(1) end, "bad argument #1 to 'global_fn'")
        assert.error(function() local_fn(1) end, "bad argument #1 to 'local_fn'")
      end)
      it("raises an argument error", function()
        assert.error(arg_error(1), "bad argument #1 to '?'")
        assert.error(arg_error(1, "message"), "bad argument #1 to '?' (message)")
      end)
    end)
    describe("blame site", function()
      it("blames the call site", function()
        assert.matches(":2: bad argument", blame('arg_error(1)'))
      end)
    end)
  end)
  describe("check_arg", function()
    local function check_arg(...)
      local args = table.pack(...)
      return function()
        checks.check_arg(table.unpack(args))
      end
    end
    describe("bad arguments", function()
      it("diagnoses bad argument #1", function()
        assert.error(check_arg(), "bad argument #1 to 'check_arg' (number expected, got no value)")
        assert.error(check_arg('not a number'), "bad argument #1 to 'check_arg' (number expected, got string)")
        assert.error(check_arg(1.337), "bad argument #1 to 'check_arg' (number has no integer representation)")
      end)
      it("diagnoses bad argument #3", function()
        assert.error(check_arg(1, false, {}), "bad argument #3 to 'check_arg' (string expected, got table)")
        assert.error(check_arg(1, false, true), "bad argument #3 to 'check_arg' (string expected, got boolean)")
      end)
      it("diagnoses bad argument using a function", function()
        local test = function()
          local foo = function(x)
            checks.check_arg(1, function(xx) return x < 0 end, "extra message")
          end
          foo(1)
        end
        assert.error(test, "bad argument #1 to 'foo' (extra message)")
      end)
    end)
    describe("raising errors", function()
      it("raises an argument error", function()
        assert.error(check_arg(1, false), "bad argument #1 to '?'")
        assert.error(check_arg(1, false, "message"), "bad argument #1 to '?' (message)")
        assert.no_error(check_arg(1, true))
        assert.no_error(check_arg(1, true))
      end)
    end)
  end)
  describe("check_types", function()
    describe("with one specifier", function()
      local function f1(tag, x)
        local function f(_) checks.check_types(tag) end
        return function() f(x) end
      end
      it("should report errors", function()
        assert.error(f1('boolean', nil), "bad argument #1 to 'f' (boolean expected, got nil)")
        assert.error(f1('function', {1337}), "bad argument #1 to 'f' (function expected, got table)")
      end)
    end)
    describe("with multiple specifiers", function()
      local function f1(tag1, tag2, x)
        local function f(_) checks.check_types(tag1, tag2) end
        return function() f(x) end
      end
      local function f2(tag1, tag2, x, y)
        local function f(_, _) checks.check_types(tag1, tag2) end
        return function() f(x, y) end
      end
      local function f3(tag1, x, y, z)
        local function f(_, _, _) checks.check_types(tag1) end
        return function() f(x, y, z) end
      end
      local function f6(x) checks.check_types('object') end

      it("should report errors", function()
        assert.error(f2('boolean', 'string', nil, nil), "bad argument #1 to 'f' (boolean expected, got nil)")
        assert.error(f2('boolean', 'string', true, nil), "bad argument #2 to 'f' (string expected, got nil)")
        assert.error(f3('*string', '1', 2, 3), "bad argument #2 to 'f' (string expected, got number)")
      end)
      it("should report missing arguments", function()
        assert.error(f1('boolean', 'string', true), "bad argument #2 to 'f' (string expected, got no value)")
      end)
      it("should use the custom check", function()
        assert.error(function() checks.register_type('object') end)
        checks.register_type("object", function() return true end)
        assert.not_error(function() f6({}) end)
        checks.unregister_type("object")
        assert.error(function() f6({}) end)
      end)
      describe("prefix '*'", function()
        local function f(...) checks.check_types('*string') end
        it("should not raise if there are no more arguments", function()
          assert.not_error(function() f() end)
          assert.not_error(function() f('a', 'b') end)
        end)
        it("should report errors", function()
          assert.error(function() f(nil) end, "bad argument #1 to 'f' (string expected, got nil)")
          assert.error(function() f(1) end, "bad argument #1 to 'f' (string expected, got number)")
          assert.error(function() f('a', 1) end, "bad argument #2 to 'f' (string expected, got number)")
        end)
      end)
      describe("prefix '+'", function()
        local function f(...) checks.check_types('+string') end
        it("should not raise errors", function()
          assert.not_error(function() f('a') end)
          assert.not_error(function() f('a', 'b') end)
        end)
        it("should report errors", function()
          assert.error(function() f() end, "bad argument #1 to 'f' (one or more of string expected, got no value)")
          assert.error(function() f(nil) end, "bad argument #1 to 'f' (string expected, got nil)")
          assert.error(function() f(1) end, "bad argument #1 to 'f' (string expected, got number)")
          assert.error(function() f('a', 1) end, "bad argument #2 to 'f' (string expected, got number)")
        end)
      end)
      describe("+any", function()
        local function f(...) checks.check_types('+any') end
        it("should not raise errors", function()
          assert.not_error(function() f('a') end)
          assert.not_error(function() f('a', 1, true) end)
        end)
        it("should report errors", function()
          assert.error(function() f() end, "bad argument #1 to 'f' (one or more of anything but nil expected, got no value)")
          assert.error(function() f(nil) end, "bad argument #1 to 'f' (anything but nil expected, got nil)")
        end)
      end)
    end)
  end)
  describe("check_type", function()
    local function check_type(...)
      local args = table.pack(...)
      return function() checks.check_type(table.unpack(args)) end
    end
    local function f1(arg, tag, x)
      local function f(_) checks.check_type(arg, tag) end
      return function() f(x) end
    end
    describe("bad arguments", function()
      it("diagnoses missing argument #1", function()
        assert.error(check_type(), "bad argument #1 to 'check_type' (number expected, got no value)")
      end)
      it("diagnoses missing argument #2", function()
        assert.error(check_type(1), "bad argument #2 to 'check_type' (string expected, got no value)")
      end)
      it("diagnoses bad argument #1", function()
        assert.error(check_type(nil, 'string'), "bad argument #1 to 'check_type' (number expected, got nil)")
        assert.error(check_type('string', 'string'), "bad argument #1 to 'check_type' (number expected, got string)")
        assert.error(check_type(1, 'string'), "bad argument #1 to 'check_type' (invalid argument index)")
      end)
      it("diagnoses bad argument #2", function()
        assert.error(check_type(1), "bad argument #2 to 'check_type' (string expected, got no value)")
        assert.error(check_type(1, {1337}), "bad argument #2 to 'check_type' (string expected, got table)")
      end)
    end)
    describe("with primitive types", function()
      it("reports missing arguments", function()
        assert.error(f1(1, 'boolean', nil), "bad argument #1 to 'f' (boolean expected, got nil)")
        assert.error(f1(1, 'thread', nil), "bad argument #1 to 'f' (thread expected, got nil)")
        assert.error(f1(1, 'function', nil), "bad argument #1 to 'f' (function expected, got nil)")
        assert.error(f1(1, 'file', nil), "bad argument #1 to 'f' (file expected, got nil)")
        assert.error(f1(1, 'integer', nil), "bad argument #1 to 'f' (integer expected, got nil)")
        assert.error(f1(1, 'number', nil), "bad argument #1 to 'f' (number expected, got nil)")
        assert.error(f1(1, 'string', nil), "bad argument #1 to 'f' (string expected, got nil)")
        assert.error(f1(1, 'table', nil), "bad argument #1 to 'f' (table expected, got nil)")
        assert.error(f1(1, 'userdata', nil), "bad argument #1 to 'f' (userdata expected, got nil)")
      end)
      it("reports mismatched types", function()
        assert.error(f1(1, 'boolean', {1337}), "bad argument #1 to 'f' (boolean expected, got table)")
        assert.error(f1(1, 'thread', {1337}), "bad argument #1 to 'f' (thread expected, got table)")
        assert.error(f1(1, 'function', {1337}), "bad argument #1 to 'f' (function expected, got table)")
        assert.error(f1(1, 'file', {1337}), "bad argument #1 to 'f' (file expected, got table)")
        assert.error(f1(1, 'integer', {1337}), "bad argument #1 to 'f' (integer expected, got table)")
        assert.error(f1(1, 'number', {1337}), "bad argument #1 to 'f' (number expected, got table)")
        assert.error(f1(1, 'string', {1337}), "bad argument #1 to 'f' (string expected, got table)")
        assert.error(f1(1, 'table', '1337'), "bad argument #1 to 'f' (table expected, got string)")
        assert.error(f1(1, 'userdata', {1337}), "bad argument #1 to 'f' (userdata expected, got table)")
      end)
      it("matches types", function()
        assert.not_error(f1(1, 'boolean', true))
        assert.not_error(f1(1, 'thread', coroutine.create(function() end)))
        assert.not_error(f1(1, 'function', function() end))
        assert.not_error(f1(1, 'file', io.stderr))
        assert.not_error(f1(1, 'number', 1.337e3))
        assert.not_error(f1(1, 'string', "a string"))
        assert.not_error(f1(1, 'table', {}))
        assert.not_error(f1(1, 'userdata', io.stderr))
        assert.not_error(f1(1, 'file', io.stderr))
        assert.not_error(f1(1, 'FILE*', io.stderr))
      end)
      it("matches optional types", function()
        assert.not_error(f1(1, '?boolean', nil))
        assert.not_error(f1(1, '?thread', nil))
        assert.not_error(f1(1, '?function', nil))
        assert.not_error(f1(1, '?file', nil))
        assert.not_error(f1(1, '?number', nil))
        assert.not_error(f1(1, '?string', nil))
        assert.not_error(f1(1, '?table', nil))
        assert.not_error(f1(1, '?userdata', nil))
      end)
      it("properly format the descriptor", function()
        assert.error(f1(1, '?a', {1337}), "bad argument #1 to 'f' (nil or a expected, got table)")
        assert.error(f1(1, '?a|b', {1337}), "bad argument #1 to 'f' (nil, a or b expected, got table)")
        assert.error(f1(1, '?a|b|c', {1337}), "bad argument #1 to 'f' (nil, a, b, or c expected, got table)")
      end)
    end)
    describe("with integer type", function()
      it("reports missing arguments", function()
        assert.error(f1(1, 'integer'), "bad argument #1 to 'f' (integer expected, got nil)")
      end)
      it("reports mismatched types", function()
        assert.error(f1(1, 'integer', {1337}), "bad argument #1 to 'f' (integer expected, got table)")
        assert.error(f1(1, 'integer', 1.337), "bad argument #1 to 'f' (integer expected, got number)")
        assert.error(f1(1, 'integer', 1.337e3), "bad argument #1 to 'f' (integer expected, got number)")
      end)
      it("matches types", function()
        assert.not_error(f1(1, 'integer', 1337))
      end)
      it("matches optional types", function()
        assert.not_error(f1(1, '?integer', nil))
      end)
    end)
    describe("with named types", function()
      local foo = setmetatable({}, { __type = "foo" })
      local goo = setmetatable({}, { __type = "goo" })
      it("reports missing arguments", function()
        assert.error(f1(1, 'foo'), "bad argument #1 to 'f' (foo expected, got nil)")
      end)
      it("report mismatching types", function()
        assert.error(f1(1, 'foo', {}), "bad argument #1 to 'f' (foo expected, got table)")
        assert.error(f1(1, 'foo', 1337), "bad argument #1 to 'f' (foo expected, got number)")
        assert.error(f1(1, 'foo', goo), "bad argument #1 to 'f' (foo expected, got table)")
      end)
      it("matches types", function()
        assert.not_error(f1(1, 'foo|goo', foo));
        assert.not_error(f1(1, 'foo|goo', goo));
      end)
    end)
    describe("with any", function()
      it("should accept anything but nil", function()
        assert.error(f1(1, 'any', nil), "bad argument #1 to 'f' (anything but nil expected, got nil)")
      end)
    end)
    describe("with options", function()
      it("should accept an option", function()
        assert.not_error(f1(1, ':one|two', 'one'))
      end)
    end)
    describe("blame site", function()
      it("blames the call site", function()
        assert.matches(":2: bad argument #1 to", blame('check_type(1, "integer")'))
      end)
    end)
  end)
  describe("#check_option", function()
    local function check_option0()
      return function()
        checks.check_option()
      end
    end
    local function check_option(...)
      local args = table.pack(...)
      return function()
        checks.check_option(table.unpack(args))
      end
    end
    local function f1(arg, tag, x)
      local function f(_)
        checks.check_option(arg, tag)
      end
      return function()
        f(x)
      end
    end
    describe("bad arguments", function()
      it("diagnoses bad argument #1", function()
        assert.error(check_option0(), "bad argument #1 to 'check_option' (number expected, got no value)")
        assert.error(check_option('not a number'), "bad argument #1 to 'check_option' (number expected, got string)")
      end)
      it("diagnoses bad argument #2", function()
        assert.error(check_option(1), "bad argument #2 to 'check_option' (string expected, got no value)")
        assert.error(check_option(1, ''), "bad argument #2 to 'check_option' (empty descriptor)")
      end)
    end)
    describe("with enum types", function()
      it("reports missing arguments", function()
        assert.error(f1(1, 'one'), "bad argument #1 to 'f' (string expected, got nil)")
        assert.error(f1(1, 'one|two'), "bad argument #1 to 'f' (string expected, got nil)")
      end)
      it("reports mismatched types", function()
        assert.error(f1(1, 'one', 'string'), "bad argument #1 to 'f' ('one' expected, got 'string')")
        assert.error(f1(1, 'one', 'two'), "bad argument #1 to 'f' ('one' expected, got 'two')")
        assert.error(f1(1, 'one|two', 'three'), "bad argument #1 to 'f' ('one' or 'two' expected, got 'three')")
        assert.error(f1(1, 'one|two|3', '4'), "bad argument #1 to 'f' ('one', 'two' or '3' expected, got '4')")
        assert.error(f1(1, 'one', 1337), "bad argument #1 to 'f' (string expected, got number)")
        assert.error(f1(1, '?one|two', 'three'), "bad argument #1 to 'f' (nil, 'one' or 'two' expected, got 'three')")
      end)
      it("matches types", function()
        -- assert.not_error(f1(1, 'one|two', 'one'))
        -- assert.not_error(f1(1, 'one|two', 'two'))
        assert.not_error(f1(1, '?one|two|three', nil))
      end)
    end)
    describe("blame site", function()
      it("blames the call site", function()
        assert.matches(":2: bad argument #1 to", blame('check_option(1, "opt")'))
      end)
    end)
  end)
end)
