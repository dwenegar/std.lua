/***
 * @module std.fs
 */

#include "fs.h"
#include "libsyserror.h"
#include "libutil.h"

#include <lauxlib.h>
#include <string.h>

#define XX _STD_RETURN_OK_ERROR

/***
 * Deletes an empty directory.
 *
 * @function remove_directory
 * @within Directory functions
 * @tparam string path the directory to delete.
 * @treturn boolean `true` if the function succeeded; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If `path` is `nil`.
 */
static int fs_remove_directory(lua_State *L)
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

    XX(fsL_remove_directory(L, path))
}

/***
 * Creates a directory.
 *
 * @function create_directory
 * @within Directory functions
 * @tparam string path the directory to create.
 * @treturn boolean `true` if the function succeeded; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If `path` is `nil`.
 */
static int fs_create_directory(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    XX(fsL_create_directory(L, path))
}

#undef XX
