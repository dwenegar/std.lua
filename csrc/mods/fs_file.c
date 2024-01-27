/***
 * @module std.fs
 */

#include "fs.h"
#include "libfs.h"
#include "libpath.h"
#include "liberror.h"
#include "libsyserror.h"
#include "libutil.h"

#include <lauxlib.h>

/***
 * Copies the content of an existing file to a new file.
 *
 * @function copy
 * @within File functions
 * @tparam string from the path of the file to copy.
 * @tparam string to the path of the destination file.
 * @tparam[boolean] overwrite `true` if the destination file can be overwritten; otherwise `false`.
 * @treturn boolean `true` if the function succeeded; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If any of `from` or `to` is `nil` or doesn't exists.
 */
static int fs_copy_file(lua_State *L)
{
    const char *from = luaL_checkstring(L, 1);
    const char *to = luaL_checkstring(L, 2);
    int overwrite = lua_toboolean(L, 3);
    _STD_RETURN_OK_ERROR(fsL_copy_file(L, from, to, overwrite))
}

/***
 * Deletes a file.
 *
 * @function remove_file
 * @within File functions
 * @tparam string path the file to delete.
 * @treturn boolean `true` if the function succeeded; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If `path` is `nil`.
 */
static int fs_remove_file(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    _STD_RETURN_OK_ERROR(fsL_remove_file(L, path))
}
