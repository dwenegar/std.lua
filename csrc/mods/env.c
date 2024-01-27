/***
 * @module std.env
 */

#include "std.h"
#include "libenv.h"
#include "libutil.h"
#include "libsyserror.h"

/***
 * Returns the current working directory.
 *
 * @function get_current_dir
 * @treturn string the current directory.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 */
static int env_get_current_dir(lua_State *L)
{
    if (envL_get_current_dir(L)) return 1;
    _STD_RETURN_NIL_ERROR
}

/***
 * Changes the current directory to a given path.
 *
 * @function set_current_dir
 * @tparam string path the path to set the current directory to.
 * @treturn boolean `true` if the operation succeed; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise If `path` is `nil`.
 */
static int env_set_current_dir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    bool ok = envL_set_current_dir(L, path);
    _STD_RETURN_OK_ERROR(ok)
}

static int env_user_dir(lua_State *L)
{
    if (envL_get_user_dir(L)) return 1;
    _STD_RETURN_NIL_ERROR
}

static int env_get_var(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int r = envL_get_var(L, name);
    if (r != -1) return r;
    _STD_RETURN_NIL_ERROR
}

static int env_set_var(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    const char *value = luaL_optstring(L, 2, NULL);
    bool ok = envL_set_var(L, name, value);
    _STD_RETURN_OK_ERROR(ok)
}

static int env_get_vars(lua_State *L)
{
    if (envL_get_vars(L)) return 1;
    _STD_RETURN_NIL_ERROR
}

extern int luaopen_std_env(lua_State *L)
{
    // clang-format off
    const struct luaL_Reg funcs[] = {
#define XX(name) { #name, env_##name },
        XX(get_current_dir)
        XX(set_current_dir)
        XX(user_dir)
        XX(get_var)
        XX(set_var)
        XX(get_vars)
        {NULL, NULL}
#undef XX
    };

    // clang-format on
    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);
    return 1;
}
