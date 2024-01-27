#include <winsock2.h>

#include "libsyserror.h"
#include "liballocator.h"
#include "libutf.h"
#include "libenv.h"

#include <userenv.h>
#include <psapi.h>
#include <windows.h>
#include <bcrypt.h>
#include <lmcons.h>

#pragma comment(lib, "Advapi32.lib")
#pragma comment(lib, "Userenv.lib")
#pragma comment(lib, "Ws2_32.lib")

#ifndef NT_SUCCESS
#define NT_SUCCESS(status) (((NTSTATUS)(status)) >= 0)
#endif

typedef NTSTATUS(NTAPI *sRtlGetVersion)(PRTL_OSVERSIONINFOEXW);
static sRtlGetVersion s_rtlGetVersion = NULL;

#define BUF_SIZE 1024

static int system_memory_total(lua_State *L)
{
    MEMORYSTATUSEX msx;
    msx.dwLength = sizeof(msx);
    if (GlobalMemoryStatusEx(&msx))
    {
        lua_pushinteger(L, (lua_Integer)msx.ullTotalPhys);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_memory_free(lua_State *L)
{
    MEMORYSTATUSEX msx;
    msx.dwLength = sizeof(msx);
    if (GlobalMemoryStatusEx(&msx))
    {
        lua_pushinteger(L, (lua_Integer)msx.ullAvailPhys);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_process_name(lua_State *L)
{
    HANDLE self = GetCurrentProcess();

    WCHAR b[BUF_SIZE];
    DWORD len = GetProcessImageFileNameW(self, b, BUF_SIZE);
    if (len > 0)
    {
        if (utfL_pushstring16(L, b)) return 1;
        _STD_RETURN_NIL_ERROR
    }

    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
    {
        _STD_RETURN_NIL_ERROR
    }

    DWORD tmp_size = BUF_SIZE;
    while (true)
    {
        tmp_size *= 2;
        WCHAR *tmp = allocatorL_allocT(L, WCHAR, (size_t)tmp_size);
        len = GetProcessImageFileNameW(self, tmp, (DWORD)tmp_size);
        if (len > 0)
        {
            bool ok = utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
            if (ok) return 1;
            _STD_RETURN_NIL_ERROR
        }

        allocatorL_free(L, tmp);
        if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        {
            _STD_RETURN_NIL_ERROR
        }
    }
}

static int system_memory_used(lua_State *L)
{
    HANDLE self = GetCurrentProcess();
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(self, &pmc, sizeof(pmc)))
    {
        lua_pushinteger(L, (lua_Integer)pmc.WorkingSetSize);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_version(lua_State *L)
{
    RTL_OSVERSIONINFOEXW os_version_info;
    ZeroMemory(&os_version_info, sizeof(RTL_OSVERSIONINFOEXW));
    os_version_info.dwOSVersionInfoSize = sizeof(RTL_OSVERSIONINFOEXW);
    NTSTATUS status = s_rtlGetVersion(&os_version_info);
    if (!NT_SUCCESS(status))
    {
        _STD_RETURN_NIL_ERROR
    }

    char b[64];
    _snprintf_s(b, sizeof(b), _TRUNCATE, "%d.%d.%d", os_version_info.dwMajorVersion, os_version_info.dwMinorVersion,
                os_version_info.dwBuildNumber);

    lua_pushstring(L, b);
    return 1;
}

static int system_user_home(lua_State *L)
{
    int r = envL_get_var(L, "USERHOME");
    if (r == 1) return 1;
    if (r == -1)
    {
        _STD_RETURN_NIL_ERROR
    }

    r = envL_get_var(L, "USERPROFILE");
    if (r == 1) return 1;
    if (r == -1)
    {
        _STD_RETURN_NIL_ERROR
    }

    HANDLE token;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_READ, &token))
    {
        _STD_RETURN_NIL_ERROR
    }

    WCHAR b[BUF_SIZE];
    DWORD len = BUF_SIZE;
    bool ok = GetUserProfileDirectoryW(token, b, &len);
    if (!ok && GetLastError() != ERROR_INSUFFICIENT_BUFFER)
    {
        CloseHandle(token);
        _STD_RETURN_NIL_ERROR;
    }

    if (len < BUF_SIZE)
    {
        ok = utfL_pushstring16(L, b);
    }
    else
    {
        WCHAR *tmp = allocatorL_allocT(L, WCHAR, len);
        ok = GetUserProfileDirectoryW(token, tmp, &len);
        CloseHandle(token);

        if (ok)
        {
            ok = utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
        }
    }

    if (ok) return 1;
    _STD_RETURN_NIL_ERROR;
}

static int system_user_name(lua_State *L)
{
    int r = envL_get_var(L, "USERNAME");
    if (r == 1) return 1;
    if (r == -1)
    {
        _STD_RETURN_NIL_ERROR
    }

    WCHAR b[BUF_SIZE];
    DWORD len = BUF_SIZE;
    if (GetUserNameW(b, &len) && utfL_pushstring16(L, b)) return 1;

    _STD_RETURN_NIL_ERROR
}

static int system_hostname(lua_State *L)
{
    WCHAR b[BUF_SIZE];
    DWORD len = GetHostNameW(b, BUF_SIZE);
    if (len == 0)
    {
        if (utfL_pushstring16(L, b)) return 1;
        _STD_RETURN_NIL_ERROR
    }
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
    {
        _STD_RETURN_NIL_ERROR
    }

    int tmp_size = BUF_SIZE;
    while (true)
    {
        tmp_size *= 2;
        WCHAR *tmp = allocatorL_allocT(L, WCHAR, (size_t)tmp_size);
        len = GetHostNameW(tmp, tmp_size);
        if (len == 0)
        {
            bool ok = utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
            if (ok) return 1;
            _STD_RETURN_NIL_ERROR
        }

        allocatorL_free(L, tmp);
        if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        {
            _STD_RETURN_NIL_ERROR
        }
    }
}

static int system_cpu_count(lua_State *L)
{
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    lua_pushinteger(L, (lua_Integer)si.dwNumberOfProcessors);
    return 1;
}

static int system_locale(lua_State *L)
{
    WCHAR b[BUF_SIZE];
    DWORD len = GetLocaleInfoEx(LOCALE_NAME_USER_DEFAULT, LOCALE_SNAME, b, BUF_SIZE);
    if (len > 0)
    {
        if (utfL_pushstring16(L, b)) return 1;
        _STD_RETURN_NIL_ERROR
    }
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
    {
        _STD_RETURN_NIL_ERROR
    }

    int tmp_size = BUF_SIZE;
    while (true)
    {
        tmp_size *= 2;
        WCHAR *tmp = allocatorL_allocT(L, WCHAR, (size_t)tmp_size);
        len = GetLocaleInfoEx(LOCALE_NAME_USER_DEFAULT, LOCALE_SNAME, tmp, tmp_size);
        if (len > 0)
        {
            bool ok = utfL_pushstring16(L, tmp);
            allocatorL_free(L, tmp);
            if (ok) return 1;
            _STD_RETURN_NIL_ERROR
        }

        allocatorL_free(L, tmp);
        if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        {
            _STD_RETURN_NIL_ERROR
        }
    }
}

static int system_close(lua_State *L)
{
    (void)L;
    WSACleanup();
    return 1;
}

static void system_init(lua_State *L)
{
    (void)L;
    if (s_rtlGetVersion == NULL)
    {
        HMODULE handle = GetModuleHandleA("ntdll.dll");
        if (handle == NULL)
        {
            syserrL_die("GetModuleHandleA", GetLastError());
        }

        s_rtlGetVersion = (sRtlGetVersion)GetProcAddress(handle, "RtlGetVersion");
        if (s_rtlGetVersion == NULL)
        {
            syserrL_die("GetProcAddress", GetLastError());
        }
    }

    WSADATA wsa_data;
    int err = WSAStartup(MAKEWORD(2, 2), &wsa_data);
    if (err != 0)
    {
        syserrL_die("WSAStartup", err);
    }
}
