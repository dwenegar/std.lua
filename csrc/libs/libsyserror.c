#include "std.h"
#include "liberror.h"
#include "libsyserror.h"

#include <lauxlib.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _STD_WINDOWS
#include <winsock2.h>
#include <windows.h>
#pragma comment(lib, "Ws2_32.lib")
#else
#include <errno.h>
#include <string.h>
#endif

#ifdef _STD_WINDOWS
const char *syserrL_strerror(const int err)
{
    static char b[256];
    DWORD len = FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                               NULL,
                               (DWORD)err,
                               MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                               b,
                               sizeof(b),
                               NULL);
    if (len)
    {
        b[len - 2] = 0;
        return b;
    }
    return _STD_UNKOWN_ERROR;
}

int syserrL_errno()
{
    int err = GetLastError();
    if (err == 0)
    {
        err = WSAGetLastError();
    }
    return err;
}
#else
const char *syserrL_strerror(const int err)
{
    return strerror(err);
}

int syserrL_errno()
{
    return errno;
}
#endif

static const char *format_error(int err, const char *prefix, size_t *len)
{
    const char *errmsg = syserrL_strerror(err);
    if (errmsg == NULL)
    {
        errmsg = "unknown error";
    }

    static char buf[256];
    int n = prefix ? sprintf_s(buf, sizeof(buf), "%s: %s (%d)", prefix, errmsg, err)
                   : sprintf_s(buf, sizeof(buf), "%s (%d)", errmsg, err);
    *len = n > 0 ? n : 0;
    return buf;
}

int syserrL_error(lua_State *L, const char *prefix, int err)
{
    syserrL_push_error(L, prefix, err);
    return lua_error(L);
}

void syserrL_push_error(lua_State *L, const char *prefix, int err)
{
    size_t len;
    const char *s = format_error(err, prefix, &len);
    lua_pushlstring(L, s, len);
}

_STD_NORETURN void syserrL_die(const char *prefix, int err)
{
    size_t len;
    const char *s = format_error(err, prefix, &len);
    fputs(s, stderr);
    abort();
}
