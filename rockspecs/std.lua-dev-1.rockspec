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
build = {
  modules = {}
}
test = {
  type = 'busted'
}
