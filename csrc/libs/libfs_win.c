#include "libfs.h"
#include "libfs_win.h"

#include "liballocator.h"
#include "libpath.h"
#include "libsyserror.h"
#include "libutf.h"

#include <assert.h>
#include <io.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>
#include <windows.h>
#include <wchar.h>

lua_Integer to_unix_time(FILETIME ft)
{
    LARGE_INTEGER li = {.HighPart = ft.dwHighDateTime, .LowPart = ft.dwLowDateTime};
    return (li.QuadPart - TIME_TICKS_TO_UNIX_EPOCH) / TIME_TICKS_PER_MILLIS;
}

bool fsL_copy_file(lua_State *L, const char *src, const char *dst, bool overwrite)
{
    const WCHAR *src16 = utfL_to_utf16(L, src);
    const WCHAR *dst16 = utfL_to_utf16(L, dst);
    BOOL r = CopyFileW(src16, dst16, !overwrite);
    utfL_free(L, dst16);
    utfL_free(L, src16);
    return r;
}

bool fsL_rename(lua_State *L, const char *src, const char *dst, bool overwrite)
{
    const WCHAR *src16 = utfL_to_utf16(L, src);
    const WCHAR *dst16 = utfL_to_utf16(L, dst);
    BOOL r = MoveFileExW(src16, dst16, overwrite ? MOVEFILE_REPLACE_EXISTING : 0);
    utfL_free(L, dst16);
    utfL_free(L, src16);
    return r;
}

bool fsL_link(lua_State *L, const char *src, const char *dst)
{
    bool r = false;
    const WCHAR *src16 = utfL_to_utf16(L, src);
    const WCHAR *dst16 = utfL_to_utf16(L, dst);

    DWORD attr = GetFileAttributesW(src16);
    if (attr != INVALID_FILE_ATTRIBUTES)
    {
        r = CreateSymbolicLinkW(dst16, src16, SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)
            || (GetLastError() == ERROR_INVALID_PARAMETER && CreateSymbolicLinkW(dst16, src16, 0));
    }
    utfL_free(L, dst16);
    utfL_free(L, src16);
    return r;
}

bool fsL_create_directory(lua_State *L, const char *path)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    BOOL r = CreateDirectoryW(path16, NULL);
    utfL_free(L, path16);
    return r;
}

bool fsL_remove_directory(lua_State *L, const char *path)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    BOOL r = RemoveDirectoryW(path16);
    utfL_free(L, path16);
    return r;
}


bool fsL_remove_file(lua_State *L, const char *path)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    BOOL r = DeleteFileW(path16);
    utfL_free(L, path16);
    return r;
}


bool fsL_exists(lua_State *L, const char *path, bool *exists)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);

    *exists = attr != INVALID_FILE_ATTRIBUTES;
    return attr != INVALID_FILE_ATTRIBUTES || GetLastError() == ERROR_FILE_NOT_FOUND;
}

bool fsL_directory_exists(lua_State *L, const char *path, bool *exists)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);

    if (attr == INVALID_FILE_ATTRIBUTES)
    {
        *exists = false;
        return false;
    }

    *exists =(attr & FILE_ATTRIBUTE_DIRECTORY) != 0 //
              && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
    return true;
}

bool fsL_file_exists(lua_State *L, const char *path, bool *exists)
{
    return fsL_is_file(L, path, exists);
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    *exists = attr != INVALID_FILE_ATTRIBUTES           //
              && (attr & FILE_ATTRIBUTE_DIRECTORY) == 0 //
              && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
    return true;
}

bool fsL_is_directory(lua_State *L, const char *path, bool *result)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    if (attr == INVALID_FILE_ATTRIBUTES) return false;
    *result = (attr & FILE_ATTRIBUTE_DIRECTORY) != 0 && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
    return true;
}

bool fsL_is_file(lua_State *L, const char *path, bool *result)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    if (attr == INVALID_FILE_ATTRIBUTES) return false;
    *result = (attr & FILE_ATTRIBUTE_DIRECTORY) == 0 && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
    return true;
}

bool fsL_is_readonly(lua_State *L, const char *path, bool *result)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    if (attr == INVALID_FILE_ATTRIBUTES) return false;
    *result = (attr & FILE_ATTRIBUTE_READONLY) != 0;
    return true;
}

bool fsL_is_symlink(lua_State *L, const char *path, bool *result)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    if (attr == INVALID_FILE_ATTRIBUTES) return false;
    *result = (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
    return true;
}

bool fsL_file_length(lua_State *L, const char *path, lua_Integer *length)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    WIN32_FILE_ATTRIBUTE_DATA file_attribute_data;
    bool b = GetFileAttributesExW(path16, GetFileExInfoStandard, &file_attribute_data);
    utfL_free(L, path16);
    if (!b) return false;
    LARGE_INTEGER li = {.LowPart = file_attribute_data.nFileSizeLow, .HighPart = file_attribute_data.nFileSizeHigh};
    *length = li.QuadPart;
    return true;
}

bool fsL_file_created(lua_State *L, const char *path, lua_Integer *time)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    WIN32_FILE_ATTRIBUTE_DATA file_attribute_data;
    bool b = GetFileAttributesExW(path16, GetFileExInfoStandard, &file_attribute_data);
    utfL_free(L, path16);
    if (!b) return false;
    *time = to_unix_time(file_attribute_data.ftCreationTime);
    return true;
}

bool fsL_file_accessed(lua_State *L, const char *path, lua_Integer *time)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    WIN32_FILE_ATTRIBUTE_DATA file_attribute_data;
    bool b = GetFileAttributesExW(path16, GetFileExInfoStandard, &file_attribute_data);
    utfL_free(L, path16);
    if (!b) return false;
    *time = to_unix_time(file_attribute_data.ftLastAccessTime);
    return true;
}

bool fsL_file_modified(lua_State *L, const char *path, lua_Integer *time)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    WIN32_FILE_ATTRIBUTE_DATA file_attribute_data;
    bool b = GetFileAttributesExW(path16, GetFileExInfoStandard, &file_attribute_data);
    utfL_free(L, path16);
    if (!b) return false;
    *time = to_unix_time(file_attribute_data.ftLastWriteTime);
    return true;
}

bool fsL_is_hidden(lua_State *L, const char *path, bool *result)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    DWORD attr = GetFileAttributesW(path16);
    utfL_free(L, path16);
    if (attr == INVALID_FILE_ATTRIBUTES) return false;
    *result = (attr & FILE_ATTRIBUTE_HIDDEN) != 0;
    return true;
}
