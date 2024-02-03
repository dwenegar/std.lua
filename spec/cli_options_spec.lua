local cli = require 'std.cli'
local flag = require 'std.cli.flag'

local function noop() end

local function run_app(app, args)
  local buf = {}
  app.writer = function(...)
    for i = 1, select('#', ...) do
      buf[#buf + 1] = select(i, ...)
    end
  end
  app.error_writer = app.writer
  cli.run(app, args)
  if #buf > 0 then
    return table.concat(buf)
  end
end

local function create_app(action)
  return cli.app {
    name = 'app',
    version = '0.0.0.0',
    action = action,
    exit = noop,
    flag.option {long = 'int', short = 'i', type = 'i'},
    flag.option {long = 'str', short = 's', type = 's'},
    flag.option {long = 'map', short = 'm', type = '{s=i}'},
    flag.option {long = 'tuple', short = 't', type = 's=i'},
    flag.option {long = 'tuple_list', short = 'T', type = '[s=i]'},
    flag.option {long = 'flag', short = 'f', type = 'F'},
    flag.option {long = 'list', short = 'l', type = '[i]'},
  }
end

describe("#cli.options", function()
    it("should create option using shortcut functions", function()
      assert.not_error(function() cli.int_option('int') end)
      assert.not_error(function() cli.string_option('str') end)
      assert.not_error(function() cli.number_option('number') end)
      assert.not_error(function() cli.char_option('char') end)
      assert.not_error(function() cli.bool_option('bool') end)
    end)
    describe("long", function()
      it("should correctly parse the arguments (--k=v)", function()
        local invoked
        local app = create_app(function(_, ctx)
          assert.same({int = 1, str = 'str', map = {a = 1, b = 2}, flag = true, list = {1,2,3}, tuple = {'c', 3}, tuple_list = {{'d', 4}, {'e', 5}}}, ctx)
          invoked = true
        end)

        invoked = false
        assert.is_nil(run_app(app, {"--int=1", "--str=str", "--map:a=1,b=2", "--flag", "--list=1,2,3","--tuple:c=3", "--tuple_list:d=4,e=5"}))
        assert.is_true(invoked)

        invoked = false
        assert.is_nil(run_app(app, {"--int", "1", "--str", "str", "--map", "a=1", "--map", "b=2", "--flag",
          "--list=1", "--list=2", "--list=3","--tuple", "c=3", "--tuple_list", "d=4", "--tuple_list", "e=5"}))
        assert.is_true(invoked)
      end)
      it("should correctly parse the arguments (--k v)", function()
        local invoked
        local app = create_app(function(_, ctx)
          assert.same({int = 1, str = 'str', map = {a = 1}, flag = true, list = {1,2,3}}, ctx)
          invoked = true
        end)

        invoked = false
        assert.is_nil(run_app(app, {"--int", "1", "--str", "str", "--map", "a=1", "--flag", "--list", "1,2,3"}))
        assert.is_true(invoked)

        invoked = false
        assert.is_nil(run_app(app, {"--int", "1", "--str", "str", "--map", "a=1", "--flag", "--list", "1", "--list", "2", "--list", "3"}))
        assert.is_true(invoked)
      end)
    end)
    describe("short", function()
      it("should correctly parse the arguments (-kv)", function()
        local invoked
        local app = create_app(function(_, ctx)
          assert.same({int = 1, str = 'str', map = {a = 1}, flag = true, list = {1,2,3}}, ctx)
          invoked = true
        end)

        invoked = false
        assert.is_nil(run_app(app, {"-i1", "-sstr", "-ma=1", "-f", "-l1,2,3"}))
        assert.is_true(invoked)

        invoked = false
        assert.is_nil(run_app(app, {"-i1", "-sstr", "-ma=1", "-f", "-l1", "-l2", "-l3"}))
        assert.is_true(invoked)
      end)
      it("should correctly parse the arguments (-k v)", function()
        local invoked
        local app = create_app(function(_, ctx)
          assert.same({int = 1, str = 'str', map = {a = 1}, flag = true, list = {1,2,3}}, ctx)
          invoked = true
        end)

        invoked = false
        assert.is_nil(run_app(app, {"-i", "1", "-s", "str", "-ma=1", "-f", "-l", "1,2,3"}))
        assert.is_true(invoked)

        invoked = false
        assert.is_nil(run_app(app, {"-i", "1", "-s", "str", "-ma=1", "-f", "-l", "1", "-l", "2", "-l", "3"}))
        assert.is_true(invoked)
      end)
      it("should correctly set the default value", function()
        local invoked
        local app = cli.app {
          name = 'app',
          version = '0.0.0.0',
          action = function(_, ctx)
            assert.same(1, ctx.required)
            invoked = true
          end,
          exit = noop,
          flag.option {long = 'required', short = 'r', required = true, type = 'i', default = 1}
        }

        invoked = false
        assert.is_nil(run_app(app))
        assert.is_true(invoked)
      end)
    end)
  end)
