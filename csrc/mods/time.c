/***
 * Function for retrieving the current system time.
 * @module std.time
 */
#include "libtime.h"
#include "libsyserror.h"

#include <lauxlib.h>
#include <lua.h>

/***
 * Returns the value of the system's monotonic clock in fractional seconds.
 * @function monotonic
 * @treturn number the value in fractional seconds of the system's monotonic clock.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_monotonic(lua_State *L)
{
    lua_Integer time;
    if (timeL_monotonic_time(&time))
    {
        lua_pushnumber(L, time / (lua_Number)NANOS_PER_SECOND);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the value of the system's monotonic clock in milliseconds.
 * @function monotonic_ms
 * @treturn integer the value in milliseconds of the system's monotonic clock.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_monotonic_ms(lua_State *L)
{
    lua_Integer time;
    if (timeL_monotonic_time(&time))
    {
        lua_pushinteger(L, time / NANOS_PER_MILLI);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the value of the system's monotonic clock in nanoseconds.
 * @function monotonic_ns
 * @treturn integer the value in nanoseconds of the system's monotonic clock.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_monotonic_ns(lua_State *L)
{
    lua_Integer time;
    if (timeL_monotonic_time(&time))
    {
        lua_pushinteger(L, time);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the current time in fractional seconds since the Unix Epoch (January 1, 1970 UTC).
 * @function current
 * @treturn number the number of fractional seconds since the Unix Epoch, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_current(lua_State *L)
{
    lua_Integer time;
    if (timeL_system_time(&time))
    {
        lua_pushnumber(L, time / (lua_Number)MILLIS_PER_SECOND);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the current time in milliseconds since the Unix Epoch (January 1, 1970 UTC).
 * @function current_ms
 * @treturn integer the number of milliseconds since the Unix Epoch, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_current_ms(lua_State *L)
{
    lua_Integer time;
    if (timeL_system_time(&time))
    {
        lua_pushinteger(L, time);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the current value of the most precise system timer in fractional seconds.
 * @function perf_counter
 * @treturn number the value of the system timer in fractional seconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_perf_counter(lua_State *L)
{
    lua_Integer time;
    if (timeL_perf_counter(&time))
    {
        lua_pushnumber(L, time / (lua_Number)NANOS_PER_SECOND);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the current value of the most precise system timer in milliseconds.
 * @function perf_counter_ms
 * @treturn integer the value of the system timer in milliseconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_perf_counter_ms(lua_State *L)
{
    lua_Integer time;
    if (timeL_perf_counter(&time))
    {
        lua_pushinteger(L, time / NANOS_PER_MILLI);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the current value of the most precise system timer in nanoseconds.
 * @function perf_counter_ns
 * @treturn integer the value of the system timer in nanoseconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_perf_counter_ns(lua_State *L)
{
    lua_Integer time;
    if (timeL_perf_counter(&time))
    {
        lua_pushinteger(L, time);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the amount of time that the process has executed in fractional seconds.
 * @function process
 * @treturn number the amount of time that the process has executed in fractional seconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_process(lua_State *L)
{
    lua_Integer time;
    if (timeL_process_time(&time))
    {
        lua_pushnumber(L, time / (lua_Number)NANOS_PER_SECOND);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the amount of time that the process has executed in milliseconds.
 * @function process
 * @treturn integer the amount of time that the process has executed in milliseconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_process_ms(lua_State *L)
{
    lua_Integer time;
    if (timeL_process_time(&time))
    {
        lua_pushinteger(L, time / NANOS_PER_MILLI);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Returns the amount of time that the process has executed in nanoseconds.
 * @function process
 * @treturn integer the amount of time that the process has executed in nanoseconds, or `nil` if the call fails.
 * @treturn string an error message if the call fails; otherwise `nil`.
 */
static int time_process_ns(lua_State *L)
{
    lua_Integer time;
    if (timeL_process_time(&time))
    {
        lua_pushinteger(L, time);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

// clang-format off
static const struct luaL_Reg funcs[] =
{
#define XX(name) { #name, time_ ## name },
    XX(current)
    XX(current_ms)
    XX(perf_counter)
    XX(perf_counter_ms)
    XX(perf_counter_ns)
    XX(monotonic)
    XX(monotonic_ms)
    XX(monotonic_ns)
    XX(process)
    XX(process_ms)
    XX(process_ns)
    { NULL, NULL }
#undef XX
};
//clang-format on

_STD_EXTERN int luaopen_std_time(lua_State *L)
{
    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);
    return 1;
}
