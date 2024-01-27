#include "std.h"

#include <lauxlib.h>

#if defined(_STD_WINDOWS)
#include "system_win.c"
#else
#include "system_unix.c"
#endif

static int system_platform(lua_State *L)
{
    lua_pushstring(L, _STD_PLATFORM);
    return 1;
}

static int system_cpu_arch(lua_State *L)
{
    lua_pushstring(L, _STD_CPU_ARCH);
    return 1;
}

static int system_cpu_endianness(lua_State *L)
{
#if _STD_BYTE_ORDER == _STD_ORDER_BIG_ENDIAN
    lua_pushstring(L, "big");
#else
    lua_pushstring(L, "little");
#endif
    return 1;
}

// clang-format off
static const struct luaL_Reg funcs[] =
{
#define XX(name) { #name, system_ ## name },
    XX(cpu_arch)
    XX(cpu_count)
    XX(cpu_endianness)
    XX(hostname)
    XX(locale)
    XX(memory_free)
    XX(memory_total)
    XX(memory_used)
    XX(platform)
    XX(process_name)
    XX(user_home)
    XX(user_name)
    XX(version)
    { NULL, NULL }
#undef XX
};
// clang-format on

_STD_EXTERN int luaopen_std_system(lua_State *L)
{
    system_init(L);
    lua_newtable(L);                    // module
    luaL_setfuncs(L, funcs, 0);         // module
    lua_newtable(L);                    // module metatable
    lua_pushcfunction(L, system_close); // module metatable function
    lua_setfield(L, -2, "__gc");        // module metatable
    lua_setmetatable(L, -2);            // module
    return 1;
}
