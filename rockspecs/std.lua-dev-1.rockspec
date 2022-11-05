-- cspell: disable
-- luacheck: no max line length
rockspec_format = '3.0'
package = 'std.lua'
version = 'dev-1'
description = {
  summary = 'A Lua standard library',
  license = 'BSD-2'
}
source = {
  url = 'git://github.com/dwenegar/std.lua.git',
}
dependencies = {
  'lua >= 5.4',
}
local function cmod(mod_src, ...)
  local sources, libs = { 'csrc/mods/' .. mod_src }, {...}
  for i = 1, #libs do
    sources[#sources+1] = 'csrc/libs/' .. libs[i]
  end
  return {sources = sources, incdirs = {'csrc', 'csrc/libs'}}
end

build = {
  modules = {
    -- C modules
    ['std.checks'] = cmod('checks.c', 'liberror.c'),
    -- Lua modules
    ['std.array'] = 'src/std/array.lua',
    ['std.debugx'] = 'src/std/debugx.lua',
    ['std.func'] = 'src/std/func.lua',
    ['std.predicates'] = 'src/std/predicates.lua',
    ['std.stringx'] = 'src/std/stringx.lua',
    ['std.tablex'] = 'src/std/tablex.lua',
  }
}
test = {
  type = 'busted'
}
