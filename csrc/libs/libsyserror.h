#pragma once

#include "std.h"

#include <errno.h>
#include <lua.h>

#define _STD_UNKOWN_ERROR "unknown error"

int syserrL_errno(void);
const char *syserrL_strerror(int err);

int syserrL_error(lua_State *L, const char *prefix, int err);
void syserrL_push_error(lua_State *L, const char *prefix, int err);
_STD_NORETURN void syserrL_die(const char *prefix, int err);

#define syserrL_last_error(L) syserrL_error(L, NULL, syserrL_errno())
#define syserrL_pushlasterror(L) syserrL_push_error(L, NULL, syserrL_errno())

#define _STD_RETURN_NIL_ERROR \
    lua_pushnil(L);           \
    syserrL_pushlasterror(L); \
    return 2;

#define _STD_RETURN_NIL_NIL_ERROR \
    lua_pushnil(L);               \
    lua_pushnil(L);               \
    syserrL_pushlasterror(L);     \
    return 3;

#define _STD_RETURN_OK_ERROR(result)          \
    bool _std_return_ok_error = (result);     \
    lua_pushboolean(L, _std_return_ok_error); \
    if (_std_return_ok_error) return 1;       \
    syserrL_pushlasterror(L);                 \
    return 2;
