/***
 * @module std.sleep
 */
#include "std.h"
#include "libtime.h"
#include "libsleep.h"
#include "libsyserror.h"

#include <lauxlib.h>
#include <limits.h>
#include <math.h>

#define MILLIS_MAX INT_MAX

static lua_Integer do_sleep(lua_State *L, lua_Integer millis)
{
    luaL_argcheck(L, (millis <= (lua_Number)MILLIS_MAX), 1, "value is too large");
    if (millis <= 0) return 0;

    lua_Integer start_time;
    if (!timeL_monotonic_time(&start_time))
    {
        return -1;
    }

    sleepL_sleep(millis);

    lua_Integer now;
    if (!timeL_monotonic_time(&now))
    {
        return -1;
    }

    lua_Integer unslept = millis - (now - start_time) / NANOS_PER_MILLI;
    return unslept < 0 ? 0 : unslept;
}

/***
 * Suspends the execution of the Lua program for a given number of seconds (max 2^32 - 1 / 1000)
 * @function sleep
 * @tparam number seconds the number of seconds for which the execution is to be suspended.
 * @treturn number the number of seconds unslept.
 * @remark the function return immediately if `seconds` is less than or equal to zero.
 */
static int sleep_sleep(lua_State *L)
{
    lua_Number seconds = luaL_checknumber(L, 1);
    lua_Integer millis = (lua_Integer)ceil(seconds * MILLIS_PER_SECOND);
    lua_Integer unslept = do_sleep(L, millis);
    if (unslept >= 0)
    {
        lua_pushnumber(L, unslept / (lua_Number)MILLIS_PER_SECOND);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

/***
 * Suspends the execution of the Lua program for a given number of milliseconds.
 * @function sleep_millis
 * @tparam integer millis the number of milliseconds for which the execution is to be suspended.
 * @treturn integer the number of milliseconds unslept.
 * @remark the function return immediately if `millis` is less than or equal to zero.
 */
static int sleep_sleep_ms(lua_State *L)
{
    lua_Integer millis = luaL_checkinteger(L, 1);
    lua_Integer unslept = do_sleep(L, millis);
    if (unslept >= 0)
    {
        lua_pushinteger(L, unslept);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

// clang-format off
static const struct luaL_Reg funcs[] =
{
    {"sleep", sleep_sleep},
    {"sleep_ms", sleep_sleep_ms},
    { NULL, NULL }
};
// clang-format on

_STD_EXTERN int luaopen_std_sleep(lua_State *L)
{
    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);
    return 1;
}
