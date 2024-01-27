#include "libfs.h"

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

bool fsL_metadata(lua_State *L, const char *path)
{
    const WCHAR *path16 = utfL_to_utf16(L, path);
    WIN32_FILE_ATTRIBUTE_DATA file_attribute_data;
    bool b = GetFileAttributesExW(path16, GetFileExInfoStandard, &file_attribute_data);
    utfL_free(L, path16);
    if (!b) return false;

    void *ud = lua_newuserdata(L, sizeof(file_attribute_data));
    if (ud == NULL) return false;
    memcpy(ud, &file_attribute_data, sizeof(file_attribute_data));
    return true;
}

lua_Integer fsL_metadata_length(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    LARGE_INTEGER li = {.LowPart = file_attribute_data->nFileSizeLow, .HighPart = file_attribute_data->nFileSizeHigh};
    return (lua_Integer)li.QuadPart;
}

lua_Integer fsL_metadata_accessed(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    return to_unix_time(file_attribute_data->ftLastAccessTime);
}

lua_Integer fsL_metadata_modified(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    return to_unix_time(file_attribute_data->ftLastWriteTime);
}

lua_Integer fsL_metadata_created(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    return to_unix_time(file_attribute_data->ftCreationTime);
}

bool fsL_metadata_is_directory(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    DWORD attr = file_attribute_data->dwFileAttributes;
    return (attr & FILE_ATTRIBUTE_DIRECTORY) != 0 && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
}

bool fsL_metadata_is_file(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    DWORD attr = file_attribute_data->dwFileAttributes;
    return (attr & FILE_ATTRIBUTE_DIRECTORY) == 0 && (attr & FILE_ATTRIBUTE_REPARSE_POINT) == 0;
}

bool fsL_metadata_is_symlink(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    DWORD attr = file_attribute_data->dwFileAttributes;
    return (attr & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
}

bool fsL_metadata_is_readonly(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    DWORD attr = file_attribute_data->dwFileAttributes;
    return (attr & FILE_ATTRIBUTE_READONLY) != 0;
}

bool fsL_metadata_is_hidden(void *ud)
{
    WIN32_FILE_ATTRIBUTE_DATA *file_attribute_data = (WIN32_FILE_ATTRIBUTE_DATA *)ud;
    DWORD attr = file_attribute_data->dwFileAttributes;
    return (attr & FILE_ATTRIBUTE_HIDDEN) != 0;
}
