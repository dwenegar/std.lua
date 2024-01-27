#pragma once

#include <lua.h>

#define STACK_SAVE int __stack_top = lua_gettop(L);
#define STACK_POP lua_pop(L, lua_gettop(L) - __stack_top);

#define _CHECKLSTRING(name, arg) \
    size_t name##_len;           \
    const char *name = luaL_checklstring(L, arg, &name##_len);

#define _OPTLSTRING(name, arg, def) \
    size_t name##_len;              \
    const char *name = luaL_optlstring(L, arg, def, &name##_len);

size_t utilL_normalize_index(lua_Integer index, size_t len);

#define utilL_from_userdata(T, ud) *(T *)ud
