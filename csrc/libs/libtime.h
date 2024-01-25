#pragma once

#include <lua.h>
#include <stdbool.h>

#define MILLIS_PER_SECOND 1000LL
#define NANOS_PER_SECOND 1000000000LL
#define NANOS_PER_MILLI 1000000LL
#define MICROS_PER_MILLI 1000LL

bool timeL_perf_counter(lua_Integer *result);
bool timeL_process_time(lua_Integer *result);
bool timeL_system_time(lua_Integer *result);
bool timeL_monotonic_time(lua_Integer *result);
