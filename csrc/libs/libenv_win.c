#include "libenv.h"
#include "liballocator.h"
#include "libsyserror.h"
#include "libutf.h"

#include <windows.h>
#include <userenv.h>
#include <psapi.h>

#pragma comment(lib, "Userenv.lib")
#pragma comment(lib, "Advapi32.lib")

#define BUF_SIZE 1024

bool envL_get_current_dir(lua_State *L)
{
    size_t tmp_len = MAX_PATH;
    WCHAR *tmp = allocatorL_allocT(L, WCHAR, tmp_len);
    while (true)
    {
        DWORD len = GetCurrentDirectoryW(tmp_len, tmp);
        if (len < tmp_len)
        {
            bool ok = len > 0 && utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
            return ok;
        }
        tmp = allocatorL_reallocT(L, WCHAR, tmp, len);
        tmp_len = len;
    }
}

bool envL_set_current_dir(lua_State *L, const char *path)
{
    WCHAR *path16 = utfL_to_utf16(L, path);
    bool ok = SetCurrentDirectoryW(path16);
    utfL_free(L, path16);
    return ok;
}

bool envL_get_user_dir(lua_State *L)
{
    if (envL_get_var(L, "USERHOME") == 1 || envL_get_var(L, "USERPROFILE") == 1)
    {
        return true;
    }

    HANDLE token;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_READ, &token))
    {
        return false;
    }

    DWORD tmp_len = MAX_PATH;
    WCHAR *tmp = allocatorL_allocT(L, WCHAR, tmp_len);

    bool ok;
    while (true)
    {
        if (GetUserProfileDirectoryW(token, tmp, &tmp_len))
        {
            ok = utfL_pushstring16(L, tmp);
            break;
        }
        if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        {
            ok = false;
            break;
        }
        tmp = allocatorL_reallocT(L, WCHAR, tmp, tmp_len);
    }
    allocatorL_free(L, tmp);
    CloseHandle(token);
    return ok;
}

int envL_get_var(lua_State *L, const char *name)
{
    WCHAR *name16 = utfL_to_utf16(L, name);
    if (name16 == NULL) return -1;

    DWORD tmp_len = BUF_SIZE;
    WCHAR *tmp = allocatorL_allocT(L, WCHAR, tmp_len);

    while (true)
    {
        DWORD len = GetEnvironmentVariableW(name16, tmp, tmp_len);
        if (len == 0 && GetLastError() == ERROR_ENVVAR_NOT_FOUND)
        {
            utfL_free(L, name16);
            allocatorL_free(L, tmp);
            return 0;
        }

        if (len < tmp_len)
        {
            utfL_free(L, name16);
            bool ok = len > 0 && utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
            return ok ? 1 : -1;
        }
        tmp = allocatorL_reallocT(L, WCHAR, tmp, len);
        tmp_len = len;
    }
}

bool envL_set_var(lua_State *L, const char *name, const char *value)
{
    WCHAR *name16 = utfL_to_utf16(L, name);
    if (name16 == NULL) return false;

    WCHAR *value16 = NULL;
    if (value != NULL)
    {
        value16 = utfL_to_utf16(L, value);
        if (value16 == NULL)
        {
            utfL_free(L, name16);
            return false;
        }
    }

    bool ok = SetEnvironmentVariableW(name16, value16) != 0;

    utfL_free(L, name16);
    if (value16 != NULL)
    {
        utfL_free(L, value16);
    }
    return ok;
}

bool envL_get_vars(lua_State *L)
{
    WCHAR *p = GetEnvironmentStringsW();
    lua_newtable(L); // env
    while (p != NULL && *p != L'\0')
    {
        WCHAR *q = p;
        WCHAR *eq = wcschr(q, L'=');
        if (eq != NULL)
        {
            utfL_pushlstring16(L, q, eq - q);
            utfL_pushstring16(L, eq + 1);
            lua_settable(L, -3);
        }

        while (*q != L'\0') q++;
        p = q + 1;
    }
    return true;
}
