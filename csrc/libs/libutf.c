#include "std.h"

#if defined(_STD_WINDOWS)

#include "liballocator.h"
#include "liberror.h"
#include "libutf.h"

#include <windows.h>

WCHAR *utfL_to_utf16x(lua_State *L, const char *utf8, size_t *utf16len)
{
    int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
    if (len == 0) return NULL;

    WCHAR *utf16 = allocatorL_mallocT(L, WCHAR, len);
    len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, utf16, len);
    if (len == 0)
    {
        allocatorL_free(L, (void *)utf16);
        return NULL;
    }
    if (utf16len != NULL)
    {
        *utf16len = len - 1;
    }
    return utf16;
}

char *utfL_to_utf8x(lua_State *L, const WCHAR *utf16, size_t *utf8len)
{
    int len = WideCharToMultiByte(CP_UTF8, 0, utf16, -1, NULL, 0, NULL, NULL);
    if (len == 0) return NULL;

    char *utf8 = allocatorL_mallocT(L, char, len);
    len = WideCharToMultiByte(CP_UTF8, 0, utf16, -1, utf8, len, NULL, NULL);
    if (len == 0)
    {
        allocatorL_free(L, (void *)utf8);
        return NULL;
    }
    if (utf8len != NULL)
    {
        *utf8len = len - 1;
    }
    return utf8;
}

bool utfL_pushstring16(lua_State *L, const WCHAR *str16)
{
    size_t str8len;
    char *str8 = utfL_to_utf8x(L, str16, &str8len);
    if (str8 == NULL) return false;

    lua_pushlstring(L, str8, str8len);
    allocatorL_free(L, (void *)str8);
    return true;
}

bool utfL_pushlstring16(lua_State *L, const WCHAR *str16, size_t str16len)
{
    size_t str8len;
    char *str8 = utfL_to_utf8x(L, str16, &str8len);
    if (str8 == NULL) return false;

    lua_pushlstring(L, str8, str16len);
    allocatorL_free(L, (void *)str8);
    return true;
}

WCHAR *utfL_cat16(lua_State *L, const WCHAR *x, const WCHAR *y, size_t *len)
{
    size_t x_len = wcslen(x);
    size_t y_len = wcslen(y);
    WCHAR *s = allocatorL_allocT(L, WCHAR, x_len + y_len + 1);
    wcsncpy_s(s, x_len + y_len, x, x_len);
    wcsncpy_s(s + x_len, y_len, y, y_len);
    s[x_len + y_len] = L'\0';
    return s;
}

#endif
