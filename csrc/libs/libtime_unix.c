
#include "std.h"
#include "libtime.h"
#include <time.h>
#include <sys/time.h>

#if defined(_STD_APPLE)
#include <mach/mach_time.h>
#endif

#define WINDOWS_TO_UNIX_EPOCH 116444736000000000LL
#define TICKS_PER_MILLIS 10000LL

// Returns the number of milliseconds since the Unix epoch.
bool timeL_system_time(lua_Integer *result)
{
    struct timeval tv;
    if (gettimeofday(&tv, NULL)) return false;
    *result = (lua_Integer)(tv.tv_sec * MILLIS_PER_SECOND + tv.tv_usec / MICROS_PER_MILLI);
    return true;
}

// Returns the value of the most precise system timer in nanoseconds.
bool timeL_perf_counter(lua_Integer *result)
{
    return timeL_monotonic_time(result);
}

// Returns the number of nanoseconds since an unknown point in time
bool timeL_monotonic_time(lua_Integer *result)
{
    static int64_t t0 = 0;
#if defined(_STD_APPLE)
    int64_t now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    if (now < 0) return false;
    if (t0 == 0) t0 = now;
    *result = now - t0;
    return true;
#else
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts)) return false;
    int64_t now = ts.tv_sec * NANOS_PER_SECOND + ts.tv_nsec;
    if (t0 == 0) t0 = now;
    *result = now - t0;
    return true;
#endif
}

bool timeL_process_time(lua_Integer *result)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts)) return false;
    *result = ts.tv_sec * NANOS_PER_SECOND + ts.tv_nsec;
    return true;
}
