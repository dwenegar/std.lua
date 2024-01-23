--- A DSL for command-line applications.
-- @module std.cli
local M = {}

local checks = require 'std.checks'
local shapes = require 'std.shapes'
local tablex = require 'std.tablex'

local cmd = require 'std.cli.cmd'
local flag = require 'std.cli.flag'
local reader = require 'std.cli.reader'

local tostring = tostring
local io_stdout = io.stdout
local io_stderr = io.stderr
local os_exit = os.exit

local _ENV = M

--- The command-line application context.
--
-- The table is passed to each `validate` and `action` function.
-- @table AppContext
-- @tfield table contains the unparsed command-line arguments.

--- Contains the customization options for a CLI application.
-- @table AppOpts
-- @tfield string name the name of the application; displayed on the application's help.
-- @tfield[opt] string summary a short description of the application; displayed on the application's help.
-- @tfield[opt] string description description of the application; displayed on the application's help.
-- @tfield[opt] function action function invoked when the program is executed (see @{action}).
-- @tfield[opt] function exit the function used to handle termination (see @{exit}).
-- @tfield[opt] string footer the text appended at the end of the application's help.
-- @tfield[opt] boolean disable_suggestions disables the suggestions based on Levenshtein distance.
-- @tfield[opt] integer distance_threshold defines minimum levenshtein distance to display suggestions.
-- @tfield[opt] boolean hide_help whether to hide or not the built-in help commands.
-- @tfield[opt] boolean hide_version whether to hide or not the built-in version option.
-- @tfield[opt] boolean show_groups whether to group or not the commands and xs into groups.
-- @tfield[opt] string usage the short description of the application.
-- @tfield[opt] string version version of the application.
-- @tfield[opt] function validate function invoked before executing the command (see @{validate}).
-- @tfield[opt] function writer function used to write the output of the application (see @{write}).

local AppProps = shapes.shape({
  name = shapes.string.required,
  action = shapes.func,
  description = shapes.string,
  examples = shapes.array_of(shapes.string),
  summary = shapes.string,
  usage = shapes.string,
  validate = shapes.func,
  disable_suggestions = shapes.boolean,
  exit = shapes.func,
  footer = shapes.string,
  hide_help = shapes.boolean,
  hide_version = shapes.boolean,
  show_groups = shapes.boolean,
  distance_threshold = shapes.integer,
  version = shapes.string,
  writer = shapes.func,
  error_writer = shapes.func
}, {mode = 'dictionary', exact = true})

--- Initialize a new command line application.
-- @tparam table opts a table with the customization options (see @{AppOpts}); the array part of the table can
-- contain flags defining the program commands, options, and arguments.
-- @treturn table a table describing the CLI application.
-- @raise If any field of the returned table is not of the right type.
-- @usage
-- cli.app {
--   name = 'hello',
--   action = function()
--     print("Hello")
--   end
-- }
function app(opts)
  checks.check_types('table')
  local err = AppProps(opts)
  if err then
    checks.arg_error(1, tostring(err))
  end

  local a = {}
  if opts then
    tablex.copy(opts, a)
  end

  a.kind = 'command'
  a.writer = a.writer or function(...)
    io_stdout:write(...)
  end
  a.error_writer = a.writer or function(...)
    io_stderr:write(...)
  end
  a.exit = a.exit or function(exit_code)
    os_exit(exit_code, true)
  end

  return a
end

--- Contains customizations for a given command.
-- @table CommandOpts
-- @tfield[opt] function action function executed when the command is invoked (see @{action}); if not specified
-- the field `command` in the application context will be set to the name of the command.
-- @tfield[opt] {string} aliases alternative names of the command.
-- @tfield[opt] string description the description of the command.
-- @tfield[opt] boolean hidden hides the command from any help text.
-- @tfield[opt] string summary text displayed on the help text of the command.
-- @tfield[opt] function validate function invoked before executing the command (see @{validate}).

--- Creates an command flag.
-- @function command
-- @tparam string name the name used to invoke the command.
-- @tparam table opts the command customization (see @{CommandOpts}).
-- @treturn table the new command flag.
-- @usage
-- local build_cmd = flag.command('build', {
--   action = function(ctx)
--     ...
--   end
-- })
-- @raise If any field of the returned table is not of the right type.
command = flag.command

--- Contains customizations for a given option.
-- @table OptionOpts
-- @tfield[opt] function action function invoked after the option has been parsed (see @{action}); if not specified
-- a field in the application context named after the option will be set to the value of the option .
-- @tfield[opt] {string} aliases the aliases of the option.
-- @tfield[opt] string arg_name the name of the argument to the option shown in the usage text.
-- @tfield[opt] string conflicts a space-separated list of options that conflict with the option.
-- @field[opt] default the default value of the option.
-- @tfield[opt] string description the description of the option shown in the usage text.
-- @tfield[opt=false] boolean global defines whether this option is global or not; a global option will be available
-- to all child commands.
-- @tfield[opt] string group the name of the option group the option belongs to.
-- @tfield[opt=false] boolean hidden hides the option in any usage text.
-- @tfield[opt=0] integer min_count the minimum number of times the option must appear in the command line.
-- @tfield[opt] integer max_count the maximum number of times the option can appear in the command line.
-- @tfield[opt] boolean once the option must appear at most once in the command line.
-- @tfield[opt=false] boolean required the option must appear at least once in the command line.
-- @tfield[opt='string'] string type the type of the option.
-- @tfield[opt] boolean unbound whether the option is unbound or not.
-- @tfield[opt] function validate function invoked after the option has been parsed, but before `action` is invoked
-- (see @{validate}).

--- Creates an option flag.
-- @function option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
-- @usage
-- local verbose = flag.option('verbose', 'v', {
--   action = function(ctx)
--     ctx.verbose = true
--   end
-- })
-- @raise If opts contains invalid values.
option = flag.option

--- Creates an option flag.
-- @function option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
-- @usage
-- local verbose = flag.option('verbose', 'v', {
--   action = function(ctx)
--     ctx.verbose = true
--   end
-- })
-- @raise If opts contains invalid values.
function global_option(...)
  local o = option(...)
  o.global = true
  return o
end

local function make_function(t)
  return function(long, short, action, opts)
    checks.check_types('string', '?string', '?function', '?table')
    opts = opts or {}
    opts.long = long
    opts.short = short
    opts.action = action
    opts.type = t
    return option(opts)
  end
end

--- Creates an option flag accepting integer values (see @{option}).
-- @function int_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
int_option = make_function 'integer'

--- Creates an option flag accepting string values (see @{option}).
-- @function string_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
string_option = make_function 'string'

--- Creates an option flag accepting number values (see @{option}).
-- @function number_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
number_option = make_function 'number'

--- Creates an option flag accepting char values (see @{option}).
-- @function char_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
char_option = make_function 'char'

--- Creates an option flag accepting boolean values (see @{option}).
-- @function bool_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the short name for the option.
-- @tparam[opt] function action the action to invoke for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
bool_option = make_function 'bool'

--- Contains customizations for a given argument.
-- @table ArgumentOpts
-- @tfield[opt] function action function invoked after the argument has been parsed (see @{action}); if not specified
-- a field in the application context named after the argument will be set to the value of the argument .
-- @tfield[opt] string default the default value of the argument.
-- @tfield[opt='boolean'] string type the type of the argument.
-- @tfield[opt] integer max_count the maximum number of times the argument can appear in the command line.
-- @tfield[opt] integer min_count the minimum number of times the argument must appear in the command line.
-- @tfield[opt] boolean once the argument must appear at most once in the command line.
-- @tfield[opt] boolean required the argument must appear at least once in the command line.
-- @tfield[opt='boolean'] string required the argument must appear at least once in the command line.
-- @tfield[opt='string'] string type the type of the argument.
-- @tfield[opt] boolean unbound whether the argument is unbound or not.
-- @tfield[opt] function validate function invoked after the argument has been parsed, but before `action`
-- (see @{validate}).

--- Creates an argument flag.
-- @function argument
-- @tparam string name the name used to set the argument value in the context.
-- @tparam table opts the argument customization (see @{ArgumentOpts}).
-- @treturn table the new argument flag.
-- @usage
-- local files = flag.argument('files', {
--   unbound = true,
--   action = function(ctx, files)
--     ctx.files = files
--   end
-- })
-- @raise If any field of the returned table is not of the right type.
argument = flag.argument

--- Registers a given function as the reader for the specified type.
-- @function add_reader
-- @tparam string typename a space separated list of type names (i.e.: `integer i`).
-- @tparam boolean requires_arg whether the reader requires an argument or not.
-- @tparam function read the function used to read a value from the command line (see @{read}).
add_reader = reader.add_reader

--- Runs an application with the specified arguments.
-- @function run
-- @tparam table app a CLI application table returned by @{app}.
-- @tparam {string} args an array containing the command-line arguments to the application.
run = cmd.run

return M

--- Function Types
-- @section fn_types

--- Represents a function used to convert a string into an option value.
-- @function read
-- @tparam string s the string to be converted.
-- @return the converted value if the conversion succeeds; otherwise `nil`.
-- @treturn string an error message if the conversion fails; otherwise `nil`.

--- Represents the function used to validate the context before executing an @{action}.
-- @function validate
-- @tparam table ctx the program context (see @{AppContext}).
-- @treturn[opt] string `nil` if the context is valid; otherwise an error message.

--- Represents the function containing the logic of a command or option.
-- @function action
-- @tparam table ctx the program context (see @{AppContext}).
-- @treturn[opt] string an error message if the action fails.

--- Writes a series of values.
-- @function write
-- @param ... the values to be written.
-- @treturn[opt] string an error message if an error occurs while writing the values.

--- Handles the termination of the application.
-- @function exit
-- @tparam integer exit_code the application exit code.
