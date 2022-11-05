local IS_WINDOWS = package.config:sub(1, 1) == '\\'

local function header(text)
  local rule = ('='):rep(#text)
  io.stdout:write('\n', rule, '\n', text, '\n', rule, '\n')
end

local function read(filename)
  local f = io.open(filename, 'rb')
  local text = f:read('a')
  f:close()
  return text
end

local function write(filename, text)
  local f = io.open(filename, 'wb')
  f:write(text)
  f:close()
end

local function replace(text, replacements)
  return (text:gsub('@([%a_]+)@', replacements))
end

header 'Checking requirements'

local function check_cmd(name)
  local cmd = IS_WINDOWS
    and (name .. '>nul 2>nul')
    or (name .. '>/dev/null 2>/dev/null')
  local ok, _, code = os.execute(cmd)
  return ok or code ~= 127
end

local missing = {}
local requirements = {'git', 'git-lfs', 'git-cliff', 'make', 'luarocks', 'luacheck', 'ldoc'}
for _, requirement in ipairs(requirements) do
  local found = check_cmd(requirement);
  print(requirement .. ': ' .. (found and '\27[32mfound' or '\27[31mmissing') .. '\27[0m')
  if not found then
    missing[#missing+1] = requirement
  end
end

if #missing > 0 then
  print("\nPlease install the missing commands")
  os.exit(1)
end

header 'Configuration'

local function git(args)
  args = IS_WINDOWS and (args:gsub('/', '\\')) or args
  local f = io.popen('git ' .. args)
  local out = f:read('a')
  f:close()
  return out:match('^(.-)%s*$')
end

local remotes = git 'remote -v'
local gh_user, gh_repo = remotes:match('github%.com:([^/]+)/([^/]+)%s+%(fetch')
local author_name = git 'config user.name'
local author_email = git 'config user.email'
local rock_name = (gh_repo:match('^(.-)%.git$')) or gh_repo
local rock_summary = "Another Lua library"
local is_lua, is_c, has_tests, has_examples
local module_name

local config

local function prompt(message, default)
  io.write(message)
  if default ~= nil then
    io.write(' [', tostring(default), ']')
  end
  io.write(': ')
  local line = io.read('l')
  return #line > 0 and line or default
end

while true do

  rock_name = prompt("Rock's name", rock_name)
  rock_summary = prompt("Rock's summary", rock_summary)
  author_name = prompt("Author's full name", author_name)
  author_email = prompt("Author's email address", author_email)
  is_lua = prompt("Is it written in Lua? (Yn)", 'Y')
  is_c = prompt("Is it written in C? (Yn)", 'n')
  has_tests = prompt("Does the module contains tests? (Yn)", 'Y')
  has_examples = prompt("Does the module contains examples? (Yn)", 'Y')

  if is_lua ~= 'Y' and is_c ~= 'Y' then
    print('\n\27[33mDefaulting to a pure Lua module\27[0m')
    is_lua = 'Y'
  end

  module_name = rock_name:match('^(.-)%.lua$')
  if not module_name then
    module_name = rock_name
  end

  local langs = {}
  if is_lua == 'Y' then langs[#langs+1] = 'Lua' end
  if is_c == 'Y' then langs[#langs+1] = 'C' end

  config = {
    ROCK_NAME = rock_name,
    ROCK_SUMMARY = rock_summary,
    AUTHOR_NAME = author_name,
    AUTHOR_EMAIL = author_email,
    GH_USER = gh_user,
    GH_REPO = gh_repo,
    MODULE_NAME = module_name,
    MODULE_LANGS = table.concat(langs, ', '),
    MODULE_HAS_TESTS = has_tests == 'Y' and 'Yes' or 'No',
    MODULE_HAS_EXAMPLES = has_examples == 'Y' and 'Yes' or 'No'
  }

  print(replace([[

The module will be initialized with:

GitHub:
- User          : @GH_USER@
- Repository    : @GH_REPO@

Rock:
- Name          : @ROCK_NAME@
- Summary       : @ROCK_SUMMARY@
- Author        : @AUTHOR_NAME@
- Author's email: @AUTHOR_EMAIL@

Module
- Name          : @MODULE_NAME@
- Languages     : @MODULE_LANGS@
- Tests         : @MODULE_HAS_TESTS@
- Examples      : @MODULE_HAS_EXAMPLES@
]], config))

  local answer = prompt("Is this correct? (Yn)", 'Y')
  if answer == 'Y' then
    break
  end
end

header 'Initialization'

local function sed(src, dst, replacements)
  print('Writing ' .. dst)
  write(dst, replace(read(src), replacements))
end

sed('docs/config.ld', 'docs/config.ld', config)
sed('Makefile', 'Makefile', config)
sed('README.md.in', 'README.md', config)
sed('LICENSE.txt', 'LICENSE.txt', config)
sed('rockspecs/rockspec.in', ('rockspecs/%s-dev-1.rockspec'):format(rock_name), config)

local function md(path)
  print('Creating directory ' .. path)
  os.execute(IS_WINDOWS
    and ('cmd /q /c md ' .. path:gsub('/', '\\'))
    or ('mkdir -p ' .. path))
end

if is_c == 'Y' then md('csrc') end
if is_lua == 'Y' then md('src') end
if has_tests == 'Y' then md('spec') end
if has_examples == 'Y' then md('examples') end

local function rm(...)
  for i = 1, select('#', ...) do
    local path = select(i, ...)
    print('Removing ' .. path)
    os.execute(IS_WINDOWS
      and ('cmd /q /c del ' .. path:gsub('/', '\\'))
      or ('rm -f ' .. path))
  end
end

rm('README.md.in', 'rockspecs/rockspec.in', 'eng/init.lua')

print [[

Done!

Depending on your choices you might need to edit or delete the following files:

- .github/workflows/build.yml
- .github/workflows/lint.yml
- docs/config.ld
- Makefile
- README.md
]]
