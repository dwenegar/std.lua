#include "std.h"
#include "libtime.h"
#include <stdint.h>
#include <windows.h>

#define WINDOWS_TO_UNIX_EPOCH 116444736000000000LL
#define TICKS_PER_MILLIS 10000LL

// Returns the number of milliseconds since the Unix epoch.
bool timeL_system_time(lua_Integer *result)
{
    // Contains a 64-bit value representing the number of 100-nanosecond intervals
    // since January 1, 1601 (UTC).
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);

    LARGE_INTEGER li;
    li.u.HighPart = ft.dwHighDateTime;
    li.u.LowPart = ft.dwLowDateTime;

    *result = (lua_Integer)((li.QuadPart - WINDOWS_TO_UNIX_EPOCH) / TICKS_PER_MILLIS);
    return true;
}

static LONGLONG mul_div(LONGLONG value, LONGLONG numer, LONGLONG denom)
{
    LONGLONG q = value / denom;
    LONGLONG r = value % denom;
    return (q * numer) + (r * numer) / denom;
}

static bool get_windows_perf_counter(lua_Integer *result)
{
    static LARGE_INTEGER frequency = {0};
    static LARGE_INTEGER t0 = {0};

    if (frequency.QuadPart == 0)
    {
        QueryPerformanceFrequency(&frequency);
    }

    LARGE_INTEGER now;
    if (!QueryPerformanceCounter(&now)) return false;
    if (t0.QuadPart == 0) t0 = now;
    *result = (lua_Integer)mul_div(now.QuadPart - t0.QuadPart, NANOS_PER_SECOND, frequency.QuadPart);
    return true;
}

// Returns the value of the most precise system timer in nanoseconds.
bool timeL_perf_counter(lua_Integer *result)
{
    return get_windows_perf_counter(result);
}

// Returns the number of nanoseconds since an unknown point in time
bool timeL_monotonic_time(lua_Integer *result)
{
    static uint64_t t0 = 0;
    uint64_t now = GetTickCount64();
    if (t0 == 0) t0 = now;
    *result = (lua_Integer)((now - t0) * NANOS_PER_MILLI);
    return true;
}

bool timeL_process_time(lua_Integer *result)
{
    HANDLE process = GetCurrentProcess();
    FILETIME creation_time, exit_time, kernel_time, user_time;
    BOOL ok = GetProcessTimes(process, &creation_time, &exit_time, &kernel_time, &user_time);
    if (!ok) return false;

    ULARGE_INTEGER large;
    large.u.LowPart = kernel_time.dwLowDateTime;
    large.u.HighPart = kernel_time.dwHighDateTime;
    lua_Integer kt = (lua_Integer)large.QuadPart;

    large.u.LowPart = user_time.dwLowDateTime;
    large.u.HighPart = user_time.dwHighDateTime;
    lua_Integer ut = (lua_Integer)large.QuadPart;

    *result = (kt + ut) * 100;
    return true;
}
