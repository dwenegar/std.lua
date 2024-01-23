local cli = require 'std.cli'
local flag = require 'std.cli.flag'
local help = require 'std.cli.help'

describe("#cli.help", function()
  it("should format the app version (no description)", function()
    local app = cli.app {
      name = "app_name",
      version = "0.0.0.0"
    }
    local actual = table.concat(help.format_version(app))
    assert.are_equal("app_name version 0.0.0.0\n\n", actual)
  end)
  it("should format the app version (description)", function()
    local app = cli.app {
      name = "app_name",
      version = "0.0.0.0",
      description = "app_description"
    }
    local actual = table.concat(help.format_version(app))
    assert.are_equal("app_description version 0.0.0.0\n\n", actual)
  end)
  it("should format the app usage", function()
    local app = cli.app {
      name = "app_name",
      summary = "app summary",
      version = "0.0.0.0",
      examples = {"app_example-1", "app_example-2"},
      flag.option {
        long = "option-1",
        type = 'i',
        default = -1,
        description = "option-1 description",
        global = true
      },
      flag.option {
        long = "option-3",
        type = 'n',
        default = -1,
        description = "option-3 description",
      },
      flag.option {
        long = "option-2",
        type = 'n',
        default = -1,
        description = "option-2 description"
      },
      flag.command {
        name = "command",
        summary = "command summary",
        description = "command description",
        aliases = {"command_alias-1", "command_alias-2"}
      },
      footer = "footer"
    }
    local expected = [[
Usage:
  app_name [options]
  app_name [command]

Examples:
  app_example-1
  app_example-2

Available Commands:
  command  command description

Global Options:
  --option-1  option-1 description

Options:
  --option-2  option-2 description
  --option-3  option-3 description

footer

]]
    local actual = table.concat(help.format_usage(app))
    assert.are_equal(expected, actual)
  end)
  it("should format the app help", function()
    local app = cli.app {
      name = "app_name",
      summary = "app summary",
      version = "0.0.0.0",
      examples = {"app_example-1", "app_example-2"},
      flag.option {
        long = "option-1",
        type = 'i',
        default = -1,
        description = "option-1 description",
        global = true
      },
      flag.option {
        long = "option-3",
        type = 'n',
        default = -1,
        description = "option-3 description",
      },
      flag.option {
        long = "option-2",
        type = 'n',
        default = -1,
        description = "option-2 description"
      },
      flag.command {
        name = "command",
        summary = "command summary",
        description = "command description",
        aliases = {"command_alias-1", "command_alias-2"}
      },
      footer = "footer"
    }
    local expected = [[
app summary

Usage:
  app_name [options]
  app_name [command]

Examples:
  app_example-1
  app_example-2

Available Commands:
  command  command description

Global Options:
  --option-1  option-1 description

Options:
  --option-2  option-2 description
  --option-3  option-3 description

footer

]]
    local actual = table.concat(help.format_help(app))
    assert.are_equal(expected, actual)
  end)
end)

