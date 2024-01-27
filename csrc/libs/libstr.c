#include "libstr.h"
#include "liballocator.h"

#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <wchar.h>

static inline bool owns(const cstr_t s)
{
    return (s.info & 1) != 0;
}

const size_t cstr_length(const cstr_t s)
{
    return s.info >> 1;
}

const cstr_t cstr_alloc(lua_State *L, size_t size)
{
    char *s = allocatorL_allocT(L, char, size);
    return (cstr_t) {.ptr = s, .info = 1};
}

void cstr_free(lua_State *L, const cstr_t s)
{
    if ((s.info & 1) != 0)
    {
        allocatorL_free(L, (void *)s.ptr);
    }
}

const cstr_t cstr_refx(const char *ptr, size_t len)
{
    return ptr == NULL ? (cstr_t) {.ptr = NULL, .info = 0}
                       : (cstr_t) {.ptr = ptr, .info = len << 1};
}

const cstr_t cstr_ref(const char *ptr)
{
    return ptr == NULL ? (cstr_t) {.ptr = NULL, .info = 0}
                       : (cstr_t) {.ptr = ptr, .info = strlen(ptr) << 1};
}

const char *cstr_ptr(const cstr_t s)
{
    const static char *empty_string = "";
    return s.ptr == NULL ? empty_string : s.ptr;
}

const cstr_t cstr_concat(lua_State *L, const cstr_t x, const cstr_t y)
{
    size_t x_len = cstr_length(x);
    size_t y_len = cstr_length(y);

    char *s = allocatorL_mallocT(L, char, x_len + y_len + 1);
    char *p = memcpy(s, x.ptr, x_len);
    p += x_len;
    memcpy(p, y.ptr, y_len);
    p += y_len;
    *p = '\0';
    return (cstr_t) {.ptr = s, .info = ((x_len + y_len) << 1) | 1};
}
