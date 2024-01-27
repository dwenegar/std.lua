/***
 * @module std.fs
 */

#include "fs.h"
#include "libpath.h"
#include "libutil.h"
#include "libsyserror.h"

#include <lua.h>

static int fs_entries_close(lua_State *L)
{
    void *ud = luaL_checkudata(L, 1, EntriesMetatableName);
    if (read_dir_close(L, ud)) return 0;
    return syserrL_last_error(L);
}

static int fs_entries_next(lua_State *L)
{
    void *ud = luaL_checkudata(L, 1, EntriesMetatableName);
    int n = read_dir_next(L, ud);
    if (n >= 0) return n;
    _STD_RETURN_NIL_ERROR
}

static void create_entries_metatable(lua_State *L)
{
    // clang-format off
    const struct luaL_Reg entries_funcs[] = {
#define XX(name) {#name, fs_entries_##name},
        XX(close)
        XX(next)
        {NULL, NULL}
        #undef XX
    };

    const struct luaL_Reg entries_meta_methods[] = {
        {"__index", NULL}, // placeholder
        {"__gc", fs_entries_close},
        {"__close", fs_entries_close},
        {NULL, NULL}
#undef XX
    };
    // clang-format on

    luaL_newmetatable(L, EntriesMetatableName); // mt
    luaL_setfuncs(L, entries_meta_methods, 0);  // mt
    luaL_newlibtable(L, entries_funcs);         // mt t
    luaL_setfuncs(L, entries_funcs, 0);         // mt t
    lua_setfield(L, -2, "__index");             // mt
    lua_pop(L, 1);                              //
}

/***
 * Returns an iterator over the entries of the specified path.
 *
 * @function entries
 * @within Directory functions
 * @tparam string path the path to get the iterator for.
 * @return an iterator over the entries of the specified path if the function succeeded;
 * otherwise an error message describing why the function failed.
 * @raise If `path` is `nil`.
 */
static int fs_entries(lua_State *L)
{
    _CHECKLSTRING(path, 1)

    bool is_directory;
    if (!fsL_is_directory(L, path, &is_directory))
    {
        _STD_RETURN_NIL_ERROR
    }

    if (!is_directory)
    {
        lua_pushnil(L);
        lua_pushstring(L, "not a directory");
        return 2;
    }

    lua_pushcfunction(L, fs_entries_next);
    if (fsL_read_dir(L, path))
    {
        luaL_setmetatable(L, EntriesMetatableName);
        lua_pushnil(L);
        lua_pushnil(L);
        return 4;
    }
    lua_pop(L, 1);
    return syserrL_last_error(L);
}
