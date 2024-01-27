#pragma once

#include "std.h"

#include <lua.h>
#include <windows.h>

#define TIME_NANOS_PER_SEC 1000000000
#define TIME_TICKS_PER_SEC (TIME_NANOS_PER_SEC / 100)
#define TIME_TICKS_PER_MILLIS (TIME_TICKS_PER_SEC / 1000)
#define TIME_TICKS_TO_UNIX_EPOCH (11644473600 * TIME_TICKS_PER_SEC)

lua_Integer to_unix_time(FILETIME ft);
