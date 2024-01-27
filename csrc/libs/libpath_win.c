// https://docs.microsoft.com/en-us/dotnet/standard/io/file-path-formats#dos-device-paths
// https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#maximum-path-length-limitation

#include "std.h"
#include "libpath.h"

#include "liballocator.h"
#include "libsyserror.h"
#include "libutf.h"

#include <assert.h>
#include <ctype.h>
#include <io.h>
#include <lauxlib.h>
#include <malloc.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <windows.h>

#define str_eq2(x, y) (*(uint16_t *)(x) == *(uint16_t *)y)
#define str_eq4(x, y) (*(uint32_t *)(x) == *(uint32_t *)y)
#define str_eq8(x, y) (*(uint64_t *)(x) == *(uint64_t *)y)

#define UNC_PREFIX "\\\\"
#define UNC_PREFIX_LEN 2

#define DEVICE_UNC_PREFIX_LEN 8

#define DEVICE_PREFIX "\\\\.\\"
#define DEVICE_PREFIX_LEN 4

#define VERBATIM_PREFIX "\\\\?\\"
#define VERBATIM_PREFIX_LEN 4

#define BUF_SIZE 512

static inline bool is_volume_sep(const char c)
{
    return c == ':';
}

static inline bool is_drive_char(const char c)
{
    return ((unsigned)c | 32) - 'a' < 26;
}

static inline bool starts_with_drive(const char *path, size_t path_len)
{
    return path_len > 1 && is_drive_char(*path++) && is_volume_sep(*path);
}

static inline bool is_valid_file_name_char(const char c)
{
    // https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fscc/2917da5c-253c-4c0e-aaf6-9dddc37d2e6e
    // all Unicode characters are legal in a filename except
    // - the characters " \ / : | < > * ?
    // - control characters, ranging from 0x00 through 0x1F
    return c > 31 && c != '\"' && c != '*' && c != '/' && c != ':' && c != '<' && c != '>' && c != '?' && c != '\\'
           && c != '|';
}

static inline bool is_valid_path_char(const char c)
{
    // As in is_valid_file_name_char plus
    // - separators: \ / :
    // - wildcards: " < > * ?
    return c > 31 && c != '|';
}

bool pathL_is_dirsep(const char c, bool verbatim)
{
    return c == _STD_PATH_DIRSEP || (!verbatim && c == _STD_PATH_ALTDIRSEP);
}

bool pathL_is_verbatim(const char *path, size_t path_len)
{
    return path_len >= VERBATIM_PREFIX_LEN && str_eq4(path, VERBATIM_PREFIX);
}

static inline bool is_device(const char *path, size_t path_len)
{
    return path_len >= DEVICE_PREFIX_LEN && str_eq4(path, DEVICE_PREFIX);
}

static inline bool is_unc(const char *path, size_t path_len)
{
    return path_len >= UNC_PREFIX_LEN && str_eq2(path, UNC_PREFIX);
}

size_t pathL_root_length(const char *path, size_t path_len, bool *verbatim_ptr)
{
    // "c:"
    if (path_len > 1 && is_volume_sep(path[1]) && is_drive_char(path[0]))
    {
        if (verbatim_ptr) *verbatim_ptr = false;
        return path_len > 2 && pathL_is_dirsep(path[2], false) ? 3 : 2;
    }

    // "//.."
    size_t root_len;

    // "\\?\..." or "\\.\..."
    bool verbatim = pathL_is_verbatim(path, path_len);
    if (verbatim_ptr) *verbatim_ptr = verbatim;

    if (verbatim || is_device(path, path_len))
    {
        if (path_len < 8 || !str_eq4(path + 4, "UNC\\"))
        {
            // "\\?\path\" or "\\.\path\"
            root_len = 4;
            for (int i = 2; root_len < path_len; root_len++)
            {
                if (pathL_is_dirsep(path[root_len], verbatim))
                {
                    root_len++;
                    break;
                }
            }
            return root_len;
        }

        // "\\?\UNC\server\share\" or "\\.\UNC\server\share\"
        root_len = 8;
        for (int i = 2; root_len < path_len; root_len++)
        {
            if (pathL_is_dirsep(path[root_len], verbatim) && --i == 0) break;
        }
        return root_len;
    }

    if (is_unc(path, path_len))
    {
        // "..server\share\"
        root_len = 2;
        for (int i = 2; root_len < path_len; root_len++)
        {
            if (pathL_is_dirsep(path[root_len], false) && --i == 0) break;
        }
        return root_len;
    }

    // \foo foo
    return pathL_is_dirsep(path[0], false) ? 1 : 0;
}

int pathL_is_absolute(const char *path, size_t path_len)
{
    return is_unc(path, path_len) || (starts_with_drive(path, path_len) && path_len > 2 && pathL_is_dirsep(path[2], 0));
}

bool pathL_is_normalized(const char *path, size_t path_len)
{
    if (path_len == 0) return 1;

    bool verbatim;
    size_t root_len = pathL_root_length(path, path_len, &verbatim);

    if (verbatim) return true;

    char last = 0;
    for (size_t i = root_len; i < path_len; i++)
    {
        char c = *path++;
        if (c == _STD_PATH_ALTDIRSEP || c == _STD_PATH_DIRSEP && last == _STD_PATH_DIRSEP)
        {
            return false;
        }
        last = c;
    }
    return true;
}

bool pathL_is_partially_qualified(const char *path, size_t path_len)
{
    if (path_len < 2) return true;
    if (pathL_is_dirsep(path[0], false))
    {
        return path[1] != '?' && !pathL_is_dirsep(path[1], false);
    }
    if (path_len > 2 && is_volume_sep(path[1]) && pathL_is_dirsep(path[2], false))
    {
        return !is_drive_char(path[0]);
    }
    return true;
}

bool pathL_is_fully_qualified(const char *path, size_t path_len)
{
    if (path_len < 2) return false;

    // "X:/"" or "X:\"
    if (is_volume_sep(path[1]) && is_drive_char(path[0]))
    {
        return path_len > 2 && pathL_is_dirsep(path[2], false);
    }

    return path[0] == '/' || path[0] == '\\' && (path[1] == '\\' || path[1] == '?');
}

int pathL_full_path(lua_State *L, const char *path, size_t path_len)
{
    if (pathL_is_verbatim(path, path_len))
    {
        lua_pushlstring(L, path, path_len);
        return 1;
    }

    size_t path16len;
    const WCHAR *path16 = utfL_to_utf16x(L, path, &path16len);

    DWORD full_path_capacity = BUF_SIZE;
    WCHAR *full_path = allocatorL_allocT(L, WCHAR, full_path_capacity);
    while (true)
    {
        DWORD full_path_len = GetFullPathNameW(path16, full_path_capacity, full_path, NULL);
        if (full_path_len < full_path_capacity)
        {
            utfL_free(L, path16);
            bool ok = full_path_len > 0 && utfL_pushstring16(L, full_path);
            allocatorL_free(L, full_path);
            if (ok) return 1;
            _STD_RETURN_NIL_ERROR
        }
        full_path = allocatorL_reallocT(L, WCHAR, full_path, full_path_len);
        full_path_capacity = full_path_len;
    }
}

void pathL_get_random_bytes(char *bytes)
{
    LARGE_INTEGER li;
    QueryPerformanceCounter(&li);
    uint64_t bits = li.LowPart * 65537 + li.HighPart;
    bits ^= (bits << 31) | (bits >> 17);
    memcpy(bytes, &bits, sizeof(uint64_t));
}

int pathL_normalize(lua_State *L, const char *path, size_t path_len)
{
    char *normalized = allocatorL_allocT(L, char, path_len);

    size_t i = 0;
    if (pathL_is_dirsep(path[0], false))
    {
        normalized[0] = _STD_PATH_DIRSEP;
        i = 1;
    }

    int skip_sep = 0;
    size_t len = i;
    while (i < path_len)
    {
        char c = path[i++];
        if (!pathL_is_dirsep(c, false))
        {
            normalized[len++] = c;
            skip_sep = 0;
        }
        else if (!skip_sep)
        {
            normalized[len++] = _STD_PATH_DIRSEP;
            skip_sep = 1;
        }
    }
    lua_pushlstring(L, normalized, len);
    allocatorL_free(L, normalized);
    return 1;
}

int pathL_canonicalize(lua_State *L, const char *path, size_t path_len)
{
    size_t path16len;
    const WCHAR *path16 = utfL_to_utf16x(L, path, &path16len);
    HANDLE h = CreateFileW(path16,
                           GENERIC_READ,
                           FILE_SHARE_READ,
                           NULL,
                           OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS,
                           NULL);
    utfL_free(L, path16);
    if (h == INVALID_HANDLE_VALUE)
    {
        lua_settop(L, 1);
        return 1;
    }

    WCHAR b[BUF_SIZE];
    DWORD len = GetFinalPathNameByHandleW(h, b, BUF_SIZE, FILE_NAME_NORMALIZED | VOLUME_NAME_DOS);
    if (len < BUF_SIZE)
    {
        CloseHandle(h);
        if (len > 0 && utfL_pushstring16(L, b)) return 1;
        _STD_RETURN_NIL_ERROR
    }

    WCHAR *tmp = allocatorL_allocT(L, WCHAR, len);
    len = GetFinalPathNameByHandleW(h, tmp, len, FILE_NAME_NORMALIZED | VOLUME_NAME_DOS);
    CloseHandle(h);
    bool ok = len > 0 && utfL_pushstring16(L, tmp);
    allocatorL_free(L, tmp);
    if (ok) return 1;
    _STD_RETURN_NIL_ERROR
}
