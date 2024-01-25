--- Simple internationalization library.
-- @module std.i18n
--
-- @usage
--    -- setting the language:
--    local i18n = require 'std.i18n'
--    i18n.set_locale('ja')
--
--    -- adding a bundle
--    i18n.add_bundle('logging')
--
--    -- translating strings
--    local L, Ln = i18n.get_bundle('logging')
--    print(L'....')
--
--    -- shorthand for add_bundle and get_bundle:
--    local L, Ln = require 'std.i18n' {
--      name = 'logging'
--    }
local M = {}

local checks = require 'std.checks'

local error = error
local pcall = pcall
local rawset = rawset
local require = require
local setmetatable = setmetatable
local tonumber = tonumber
local type = type

local tbl_pack = table.pack
local tbl_concat = table.concat

local str_format = string.format

local _ENV = M

local DEFAULT_LOCALE = 'en'

local function errorf(fmt, ...)
  return error(fmt:format(...), 2)
end

local current_locale

local bundles = {}
local classifiers = {}

--- Registers a classifier for a given locale.
-- @tparam string locale the locale to register the classifier for.
-- @tparam function classifier the classifier function (see @{classifier}).
-- @raise If `locale` is either `nil` or not a valid value; or if a classifier
-- for the given locale has already been set.
function set_classifier(locale, classifier)
  checks.check_types('string', 'function')
  if not locale:match('^%w%w_%w%w$') and not locale:match('^%w%w$') then
    checks.arg_error(1, str_format("invalid locale: %s", locale))
  end
  if classifier and classifiers[locale] then
    errorf("classifier %q already registered", locale)
  end
  classifiers[locale] = classifier
end

--- Sets the runtime locale.
-- @tparam string locale the locale specifier (either <language><country> or <language>).
-- @raise If `locale` is either `nil` or not a valid value; or if the locale has already been set.
function set_locale(locale)
  checks.check_types('string')
  if not locale:match('^%w%w_%w%w$') and not locale:match('^%w%w$') then
    checks.arg_error(1, "invalid locale: " .. locale)
  end
  if current_locale then
    error("locale already set")
  end
  current_locale = locale
end

--- Returns the runtime locale.
-- @treturn string the current locale.
function get_locale()
  return current_locale or DEFAULT_LOCALE
end

local metatables = {
  ['silent'] = {
    __newindex = false,
    __index = function(t, k)
      rawset(t, k, k)
      return k
    end
  },
  ['nil'] = {
    __newindex = false
  },
  ['error'] = {
    __newindex = false,
    __index = function(_, k)
      errorf("missing key %q", k)
    end
  }
}

--- Add a new bundle.
-- @tparam string name the name of the bundle to add.
-- @tparam[opt] string mode specifies the how missing keys are handled; the possible values are:
--
-- - `'error'`: missing keys will raise an error;
-- - `'silent'`: missing keys will return the key value;
-- - `'nil'`: missing keys will return `nil`.
-- @tparam[optchain] string package the name of the packages containing the locales (defaults to `<name>.locales`).
-- @raise If a bundle with the same name has already been added.
-- @usage
-- local i18n = require 'std.i18n'
-- i18n.add_bundle('foo', 'silent', 'locales')
function add_bundle(name, mode, package)
  checks.check_types('string', '?string', '?string')
  checks.check_option(2, '?error|silent|nil')
  if bundles[name] then
    errorf("bundle %q already registered", name)
  end
  bundles[name] = {
    name = name,
    mode = mode or 'silent',
    package = package or name .. '.locales',
  }
end

local function format_with_pattern(s, ...)
  local args = tbl_pack(...)
  local b, ss, i = {}, s, 1
  repeat
    local h, n, fmt, t = ss:match('^(.-)%%(%d*)%$?([^%%]+)(.*)$')
    i = tonumber(n) or i
    b[#b + 1] = h
    b[#b + 1] = ('%' .. fmt):format(args[i])
    ss = t
  until #ss == 0
  return tbl_concat(b)
end

local function format_with_position(s, arg1)
  return (s:gsub('%$([^%$%s%%]+)([%%%S]*)', function(w, fmt)
    w = arg1[tonumber(w) or w]
    return #fmt == 0 and w or fmt:format(w)
  end))
end

local function format(s, arg1, ...)
  if type(arg1) == 'table' then
    return format_with_position(s, arg1)
  elseif s:find('%%%d+%$') then
    return format_with_pattern(s, arg1, ...)
  end
  return s:format(arg1, ...)
end

local function L(bundle, key, ...)
  local s = bundle.strings[key]
  return s and format(s, ...)
end

local function Ln(bundle, key, qty, ...)
  local s = bundle.strings[key]
  if type(s) == 'table' then
    local rule = bundle.classify(qty)
    local plural = rule and s[rule]
    if not plural then
      plural, s[rule] = key, key
    end
    s = plural
  end
  return s and format(s:format(qty), ...)
end

--- Returns the localization functions for a given name.
-- @tparam string name the name to get the functions for.
-- @treturn function a function that can be used to translate a single string.
-- @treturn function a function that can be used to translate singulars and plurals in a single string.
-- @raise If the requested bundle is missing; or if the strings for the requested bundle cannot be loaded.
-- @usage
-- local i18n = require 'std.i18n'
-- local L, Ln = i18n.get_bundle('foo')
--
-- L"Hello" -- Hello
-- L("Hello %s", 'Alice') -- Hello Alice
-- L("Hello $name", {name='Alice'}) -- Hello Alice
--
-- L("%2$s %1$s", 'Alice', 'Hello') -- Hello Alice
--
-- Ln("%d cat", 1) -- 1 cat
-- Ln("%d cat", 3) -- 3 cats
function get_bundle(name)
  checks.check_types('string')
  local bundle = bundles[name]
  if not bundle then
    errorf("missing bundle %q", name)
  end

  local function load_strings(locale)
    local ok, strings = pcall(require, ('%s.%s'):format(bundle.package, locale))
    if not ok then
      local lang = locale:match('^(%w%w)_')
      if lang then
        ok, strings = pcall(require, ('%s.%s'):format(bundle.package, lang))
      end
    end
    return ok, strings
  end

  if not bundle.L then
    local locale = current_locale or DEFAULT_LOCALE
    local ok, strings = load_strings(locale)
    if not ok then
      errorf("missing locale %q for bundle %q", locale, name)
    end
    bundle.strings = setmetatable(strings, metatables[bundle.mode])
    bundle.L = function(...)
      return L(bundle, ...)
    end
    bundle.Ln = function(...)
      return Ln(bundle, ...)
    end
    local classify = classifiers[locale]
    if not classify and #locale > 2 then
      local lang = locale:sub(1, 2)
      classify = classifiers[lang]
    end
    bundle.classify = classify or function(v)
      return v == 1 and 'one' or 'other'
    end
  end
  return bundle.L, bundle.Ln
end

--- Returns the name of the default locale.
-- @treturn string the name of the default locale.
function get_default_locale()
  return DEFAULT_LOCALE
end

return setmetatable(M, {
  __newindex = false,
  __call = function(_, config)
    checks.check_type(2, 'table')
    add_bundle(config.name, config.mode, config.package)
    return get_bundle(config.name)
  end
})

--- Function Types
-- @section function_types

--- Returns the classification of a given value.
-- Possible values are:
--
-- * `'zero'`
-- * `'one'`
-- * `'two'`
-- * `'few'`
-- * `'many'`
-- * `'other'`
--
-- @function classifier
-- @tparam number v the value to be classified.
-- @treturn string one of the possible classifications for `v`.
