#pragma once

#include <lua.h>
#include <lauxlib.h>
#include <stdbool.h>

bool envL_get_current_dir(lua_State *L);
bool envL_set_current_dir(lua_State *L, const char *path);
bool envL_get_user_dir(lua_State *L);
// return 0 if not found, 1 if ok, -1 if error
int envL_get_var(lua_State *L, const char *name);
bool envL_get_vars(lua_State *L);
bool envL_set_var(lua_State *L, const char *name, const char *value);
