#include "std.h"
#include "libtime.h"
#include "libsleep.h"

#include <lauxlib.h>
#include <limits.h>
#include <math.h>
#include <time.h>

void sleepL_sleep(lua_Integer millis)
{
    struct timespec rqtp, rmtp;
    rqtp.tv_sec = millis / 1000;
    rqtp.tv_nsec = (millis % 1000) * 1000000;
    nanosleep(&rqtp, &rmtp);
}
