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
    ['std.env'] = cmod('env.c', 'libenv.c', 'liballocator.c', 'libutf.c', 'liberror.c', 'libsyserror.c'),
    ['std.fs.native'] = cmod('fs.c', 'libfs.c', 'liballocator.c', 'libpath.c', 'libutil.c', 'libstr.c', 'libutf.c', 'liberror.c', 'libsyserror.c'),
    ['std.hash'] = cmod('hash.c'),
    ['std.path'] = cmod('path.c', 'libpath.c', 'libutil.c', 'liballocator.c', 'libutf.c', 'liberror.c', 'libsyserror.c'),
    ['std.sleep'] = cmod('sleep.c', 'libsleep.c', 'libtime.c', 'liberror.c', 'libsyserror.c'),
    ['std.system'] = cmod('system.c', 'libenv.c', 'liballocator.c', 'libutf.c', 'liberror.c', 'libsyserror.c'),
    ['std.time'] = cmod('time.c', 'libtime.c', 'liberror.c', 'libsyserror.c'),
    -- Lua modules
    ['std.array'] = 'src/std/array.lua',
    ['std.cli'] = 'src/std/cli.lua',
    ['std.cli.cmd'] = 'src/std/cli/cmd.lua',
    ['std.cli.flag'] = 'src/std/cli/flag.lua',
    ['std.cli.help'] = 'src/std/cli/help.lua',
    ['std.cli.parser'] = 'src/std/cli/parser.lua',
    ['std.cli.reader'] = 'src/std/cli/reader.lua',
    ['std.cli.util'] = 'src/std/cli/util.lua',
    ['std.convert'] = 'src/std/convert.lua',
    ['std.debugx'] = 'src/std/debugx.lua',
    ['std.func'] = 'src/std/func.lua',
    ['std.i18n'] = 'src/std/i18n.lua',
    ['std.iox'] = 'src/std/iox.lua',
    ['std.oo'] = 'src/std/oo.lua',
    ['std.predicates'] = 'src/std/predicates.lua',
    ['std.pretty'] = 'src/std/pretty.lua',
    ['std.shapes'] = 'src/std/shapes.lua',
    ['std.stringx'] = 'src/std/stringx.lua',
    ['std.tablex'] = 'src/std/tablex.lua',
    ['std.term.colors'] = 'src/std/term/colors.lua',
    ['std.term.cursor'] = 'src/std/term/cursor.lua',
    ['std.term.pager'] = 'src/std/term/pager.lua',
  }
}
test = {
  type = 'busted'
}
