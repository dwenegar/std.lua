#include "libfs.h"

#include "liballocator.h"
#include "libpath.h"
#include "libsyserror.h"
#include "libutf.h"
#include "libstr.h"

#include <assert.h>
#include <io.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>
#include <windows.h>
#include <wchar.h>

typedef struct entries_s
{
    bool first;
    bool closed;
    HANDLE handle;
    WIN32_FIND_DATAW wfd;
} entries_t;

static int push_filename(lua_State *L, const WCHAR *filename16)
{
    const char *filename = utfL_utf16_to_utf8(L, filename16);
    if (filename == NULL) return -1;
    lua_pushstring(L, filename);
    utfL_free(L, filename);
    return 1;
}

int read_dir_next(lua_State *L, void *ud)
{
    entries_t *entries = (entries_t *)ud;
    if (entries->closed) return 0;
    if (entries->first)
    {
        entries->first = false;
        return push_filename(L, entries->wfd.cFileName);
    }

    if (FindNextFileW(entries->handle, &entries->wfd) != 0)
    {
        return push_filename(L, entries->wfd.cFileName);
    }

    if (GetLastError() != ERROR_NO_MORE_FILES) return -1;

    entries->closed = true;
    FindClose(entries->handle);
    return 0;
}

bool read_dir_close(lua_State *L, void *ud)
{
    entries_t *entries = (entries_t *)ud;
    if (!entries->closed && entries->handle != INVALID_HANDLE_VALUE)
    {
        entries->closed = true;
        FindClose(entries->handle);
    }
    return true;
}

bool fsL_read_dir(lua_State *L, const char *path)
{
    cstr_t pattern = cstr_concat(L, cstr_ref(path), cstr_literal("/*"));
    WCHAR *pattern16 = utfL_to_utf16(L, cstr_ptr(pattern));
    cstr_free(L, pattern);
    if (pattern16 == NULL) return false;

    WIN32_FIND_DATAW wfd;
    HANDLE h = FindFirstFileExW(pattern16, FindExInfoStandard, &wfd, FindExSearchNameMatch, NULL, 0);
    utfL_free(L, pattern16);
    if (h == INVALID_HANDLE_VALUE) return false;

    entries_t *ud = (entries_t *)lua_newuserdata(L, sizeof(entries_t));
    if (ud == NULL) return false;
    ud->wfd = wfd;
    ud->first = true;
    ud->closed = false;
    ud->handle = h;
    return true;
}
