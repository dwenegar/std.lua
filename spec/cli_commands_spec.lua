local cli = require 'std.cli'

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
  return table.concat(buf)
end

local function create_app()
  return cli.app {
    name = 'app',
    version = '0.0.0.0',
    action = noop,
    exit = noop,
    cli.command {
      name = 'command'
    }
  }
end

describe("#cli.commands", function()
  describe("version", function()
    it("should fail running the version command", function()
      local app = create_app()
      app.hide_version = true

      local expected

      expected = "Error: unknown option '--version'\nRun 'app --help' for usage\n\n"
      assert.are_equal(expected, run_app(app, {"--version"}))

      expected = "Error: unknown command 'version'\nRun 'app --help' for usage\n\n"
      assert.are_equal(expected, run_app(app, {"version"}))
    end)
    it("should print the application's version", function()
      local app = create_app()
      local expected = "app version 0.0.0.0\n\n"
      assert.are_equal(expected, run_app(app, {"--version"}))
      assert.are_equal(expected, run_app(app, {"version"}))
    end)
  end)
  describe("help", function()
    it("should fail executing the application's help command", function()
      local app = create_app()
      app.hide_help = true

      local expected = "Error: unknown option '--help'\n\n"
      assert.are_equal(expected, run_app(app, {"--help"}))
    end)

    it("should print the application's help", function()
      local app = create_app()

      local expected = [[
Usage:
  app [options]
  app [command]

Available Commands:
  command
  help     Help for any command
  version  Show the program name and version

Options:
  -h, --help     Help for app
  -V, --version  Show the program name and version

]]
      assert.are_equal(expected, run_app(app, {"--help"}))
      assert.are_equal(expected, run_app(app, {"help"}))
    end)

    it("should fail running the command's help command", function()
      local app = create_app()
      app.hide_help = true

      local expected = "Error: unknown command 'help'\n\n"
      assert.are_equal(expected, run_app(app, {"help", "command"}))
    end)

    it("should print the command help", function()
      local app = create_app()

      local expected = [[
Usage:
  app command [options]

Options:
  -h, --help  Help for app command

]]
      assert.are_equal(expected, run_app(app, {"help", "command"}))
    end)
  end)
end)
