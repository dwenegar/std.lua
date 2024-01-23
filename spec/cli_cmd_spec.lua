local cli = require 'std.cli'
local cmd = require 'std.cli.cmd'
local flag = require 'std.cli.flag'

local function noop() end

local function run_command(c, args)
  local buf = {}
  c.exit = noop
  c.writer = function(...)
    for i = 1, select('#', ...) do
      buf[#buf + 1] = select(i, ...)
    end
  end
  c.error_writer = c.writer
  cmd.run(c, args)
  if #buf > 0 then
    return table.concat(buf)
  end
end

describe("#cli.cmd", function()
  describe("root command", function()
    local function create_command(action)
      return flag.command {
        name = 'root',
        action = action,
        flag.argument {name = 'args', count = 2}
      }
    end
    it("should correctly parse the arguments", function()
      local invoked
      local c = create_command(function(_, ctx)
        assert.same({"1", "2"}, ctx.args)
        assert.same({"3"}, ctx._)
        invoked = true;
      end)
      assert.is_nil(run_command(c, {"1", "2", "3"}))
      assert.is_true(invoked)
    end)
    it("should report an error if the arguments are not correct", function()
      local expected = [[
Error: missing required argument 'args'
Run 'root --help' for usage

]]
      assert.are_equal(expected, run_command(create_command(), {}))
    end)
    it("shouldn't report any error if the arguments are not correct", function()
      local c = create_command()
      c.no_errors = true
      assert.is_nil(run_command(c, {}))
    end)
  end)
  describe("sub-command", function()
    local function create_command(action)
      return flag.command {
        name = 'root',
        flag.command {
          name = 'child',
          action = action,
          flag.argument {name = 'args', count = 2}
        }
      }
    end
    it("should correctly parse the arguments", function()
      local invoked
      local c = create_command(function(_, ctx)
        assert.same({"1", "2"}, ctx.args)
        assert.same({"3"}, ctx._)
        invoked = true;
      end)
      assert.is_nil(run_command(c, {"child", "1", "2", "3"}))
      assert.is_true(invoked)
    end)
    it("should report an error if the arguments are not correct", function()
      local expected = [[
Error: unknown command 'unknown'
Run 'root --help' for usage

]]
      assert.are_equal(expected, run_command(create_command(), {"unknown"}))

      expected = [[
Error: missing required argument 'args'
Run 'root child --help' for usage

]]
      assert.are_equal(expected, run_command(create_command(), {"child"}))
    end)
    it("shouldn't report any error if the arguments are not correct", function()
      local c = create_command()
      c.no_errors = true
      assert.is_nil(run_command(c, {"child"}))
      assert.is_nil(run_command(c, {"unknown"}))
    end)
  end)

  describe("parse child and parent options", function()
    local function create_command()
      return flag.command {
        name = 'root',
        flag.option {long = 'int', short = 'i', type = 'i', default = -1},
        flag.command {
          name = 'child',
           flag.option {long = 'str', short = 's', type = 's', default = ""}
          }
      }
    end

    it("should have no output", function()
      assert.is_nil(run_command(create_command(), {"-i1", "child", "-str", "one", "--", "two"}))
    end)

    it("should correctly parse the arguments", function()
      run_command(create_command(), {"child", "--int=1", "--str=str", "one", "--", "two"}, function(_, ctx)
        assert.are_equal(1, ctx.int)
        assert.are_equal("str", ctx.str)
        assert.same({"one", "two"}, ctx._)
      end)
    end)
  end)

  describe("aliases", function()
    local function create_command(action)
      return flag.command {
        name = 'root',
        flag.command {
          name = 'child',
          aliases = {'child_alias'},
          action = action,
          flag.argument {name = 'args', count = 2}
        }
      }
    end

    it("should correctly parse the arguments", function()
      local invoked
      local c = create_command(function(_, ctx)
        assert.same({"1", "2"}, ctx.args)
        invoked = true
      end)
      run_command(c, {"child_alias", "1", "2"})
      assert.is_true(invoked)
    end)

    it("should report an unknown command", function()
      local expected = [[
Error: unknown command 'unknown'
Run 'root --help' for usage

]]
      assert.are_equal(expected, run_command(create_command(), {"unknown"}))
    end)

    it("should not report errors with 'no_errors'", function()
      local c = create_command();
      c.no_errors = true
      assert.is_nil(run_command(c, "unknown"))
    end)
  end)

  describe("options", function()
    local function create_command(action)
      return flag.command {
        name = 'root',
        action = action,
        flag.option {long = 'int', short = 'i', type = 'i', default = -1},
        flag.option {long = 'str', short = 's', type = 's', default = ""},
        flag.option {long = 'map', short = 'm', type = '{s=i}', default = ""}
      }
    end

    describe("long", function()
      it("should correctly parse the arguments (--k=v)", function()
        local invoked
        local c = create_command(function(_, ctx)
          assert.same({_ = {'one', 'two'}, int = 1, str = 'str', map = {a = 1}}, ctx)
          invoked = true
        end)
        run_command(c, {"--int=1", "--str=str", "--map:a=1", "one", "--", "two"})
        assert.is_true(invoked)
      end)
      it("should correctly parse the arguments (--k v)", function()
        local invoked
        local c = create_command(function(_, ctx)
          assert.same({_ = {'one', 'two'}, int = 1, str = 'str', map = {a = 1}}, ctx)
          invoked = true
        end)
        run_command(c, {"--int", "1", "--str", "str", "--map:a=1", "one", "--", "two"})
        assert.is_true(invoked)
      end)
    end)

    describe("short", function()
      it("should correctly parse the arguments (-kv)", function()
        local invoked
        local c = create_command(function(_, ctx)
          assert.same({_ = {'one', 'two'}, int = 1, str = 'str', map = {a = 1}}, ctx)
          invoked = true
        end)
        run_command(c, {"-i1", "-sstr", "-ma=1", "one", "--", "two"})
        assert.is_true(invoked)
      end)
      it("should correctly parse the arguments (-k v)", function()
        local invoked
        local c = create_command(function(_, ctx)
          assert.same({_ = {'one', 'two'}, int = 1, str = 'str', map = {a = 1}}, ctx)
          invoked = true
        end)
        run_command(c, {"-i", "1", "-s", "str", "-ma=1", "one", "--", "two"})
        assert.is_true(invoked)
      end)
    end)
  end)

  describe("suggestions", function()
    it("should suggest the child command", function()
      local template = "Error: unknown command '%s'\n\nDid you mean?\n        child\n\nRun 'suggestions --help' for usage\n\n"
      local template_wo_suggestion = "Error: unknown command '%s'\nRun 'suggestions --help' for usage\n\n"

      local root = flag.command {
        name = 'suggestions',
        flag.command {name = 'child'}
      }
      local typos = {chold = "child", childs = "child", children = ""}
      for typo, suggestion in pairs(typos) do
        if #suggestion > 0 then
          assert.are_equal(template:format(typo), run_command(root, {typo}))
        else
          assert.are_equal(template_wo_suggestion:format(typo), run_command(root, {typo}))
        end
      end
    end)

    it("shouldn't suggest the child command", function()
      local root = cli.app {
        name = 'app',
        disable_suggestions = true,
        flag.command {
          name = 'suggestions',
          flag.command {
            name = 'child'
          }
        }
      }
      local expected = [[
Error: unknown command '%s'
Run 'app suggestions --help' for usage

]]
      local typos = {"chold", "childs"}
      for _, typo in ipairs(typos) do
        assert.are_equal(expected:format(typo), run_command(root, {'suggestions', typo}))
      end
    end)
  end)
end)
