#pragma once

#include <lua.h>
#include <stdint.h>
#include <stdbool.h>
#include <windows.h>

char *utfL_to_utf8x(lua_State *L, const WCHAR *utf16, size_t *utf8len);
WCHAR *utfL_to_utf16x(lua_State *L, const char *utf8, size_t *utf16len);

#define utfL_utf16_to_utf8(L, x) utfL_to_utf8x(L, x, NULL)
#define utfL_to_utf16(L, x) utfL_to_utf16x(L, x, NULL)

bool utfL_pushstring16(lua_State *L, const WCHAR *str16);
bool utfL_pushlstring16(lua_State *L, const WCHAR *str16, size_t str16len);

void utfL_free(lua_State *L, const WCHAR *str16);

WCHAR *utfL_cat16(lua_State *L, const WCHAR *x, const WCHAR *y, size_t *len);
