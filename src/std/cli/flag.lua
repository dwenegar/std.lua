local M = {}

local tablex = require 'std.tablex'
local checks = require 'std.checks'
local reader = require 'std.cli.reader'
local shapes = require 'std.shapes'

local error = error
local tostring = tostring
local math_max = math.max

local _ENV = M

local function setup_occurrences(flag)
  if flag.unbound and flag.once then
    error("property 'once' conflicts with 'unbound'")
  end
  if flag.unbound and flag.count then
    error("property 'count' conflicts with 'unbound'")
  end
  if flag.once and flag.count then
    error("property 'once' conflicts with 'count'")
  end

  local min_count = flag.count or 0
  local max_count = flag.count or 1
  flag.min_count = flag.min_count or min_count
  flag.max_count = flag.max_count or max_count
  if flag.unbound then
    flag.max_count = nil
  end
  if flag.once then
    flag.max_count = 1
  end
  if flag.required then
    flag.min_count = math_max(1, flag.min_count)
  end
end

local CommandShape = shapes.shape({
  name = shapes.pattern('^%S+$').required,
  action = shapes.func,
  aliases = shapes.array_of(shapes.string),
  description = shapes.string,
  examples = shapes.array_of(shapes.string),
  group = shapes.string,
  hidden = shapes.boolean,
  summary = shapes.string,
  validate = shapes.func
}, {mode = 'dictionary', exact = true})

function command(opts)
  checks.check_types('table')
  local err = CommandShape(opts)
  if err then
    checks.arg_error(1, tostring(err))
  end

  local c = {}
  if opts then
    tablex.copy(opts, c)
  end

  c.kind = 'command'
  return c
end

local OptionsProps = shapes.shape({
  long = shapes.pattern('^%a[%-_%w]*%w$').required,
  short = shapes.pattern('^%a$'),
  action = shapes.func,
  arg_name = shapes.string,
  conflicts = shapes.array_of(shapes.string),
  count = shapes.integer,
  description = shapes.string,
  default = shapes.any,
  global = shapes.boolean,
  group = shapes.string,
  hidden = shapes.boolean,
  max_count = shapes.integer,
  min_count = shapes.integer,
  once = shapes.boolean,
  required = shapes.boolean,
  type = shapes.string,
  unbound = shapes.boolean,
  validate = shapes.func
}, {exact = true})

function option(opts)
  checks.check_types('table')
  local err = OptionsProps(opts)
  if err then
    checks.arg_error(1, tostring(err))
  end

  local o = {}
  if opts then
    tablex.copy(opts, o)
  end

  o.kind = 'option'
  o.type = o.type or 'flag'
  o.reader = reader.create(o.type)
  setup_occurrences(o)
  return o
end

local ArgumentShape = shapes.shape({
  name = shapes.pattern('^%S+$').required,
  action = shapes.func,
  count = shapes.integer,
  description = shapes.string,
  hidden = shapes.boolean,
  max_count = shapes.integer,
  min_count = shapes.integer,
  once = shapes.boolean,
  required = shapes.boolean,
  type = shapes.string,
  unbound = shapes.boolean,
  validate = shapes.func
}, {mode = 'dictionary', exact = true})

function argument(opts)
  checks.check_types('table')
  local err = ArgumentShape(opts)
  if err then
    checks.arg_error(2, tostring(err))
  end

  local a = {}
  if opts then
    tablex.copy(opts, a)
  end

  a.kind = 'argument'
  a.type = a.type or 'string'
  a.reader = reader.create(a.type)
  setup_occurrences(a)
  return a
end

return M
