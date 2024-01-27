/***
 * @module std.fs
 */

#include "fs.h"
#include "libpath.h"
#include "libsyserror.h"
#include "libutil.h"

#include <lauxlib.h>
#include <string.h>

/***
 * @type Metadata
 * A type representing the metadata of a path.
 */

#define XX(name)                                                   \
    static int fs_metadata_##name(lua_State *L)                    \
    {                                                              \
        void *ud = luaL_checkudata(L, 1, AttributesMetatableName); \
        lua_pushinteger(L, fsL_metadata_##name(ud));               \
        return 1;                                                  \
    }

/***
 * Gets the size of the file the metadata is for.
 *
 * @function accessed
 * @treturn integer the last access time for the file.
 * @remark The returned value corresponds to the number of milliseconds elapsed
 * since the Unix Epoch.
 */
XX(length)

/***
 * Gets the last access time for the file the metadata is for.
 *
 * @function accessed
 * @treturn integer the last access time for the file.
 * @remark The returned value corresponds to the number of milliseconds elapsed
 * since the Unix Epoch.
 */
XX(accessed)

/***
 * Gets the creation time for the file the metadata is for.
 *
 * @function created
 * @treturn integer the creation time for the file.
 * @remark The returned value corresponds to the number of milliseconds elapsed
 * since the Unix Epoch.
 */
XX(created)

/***
 * Gets the last modification time for the file the metadata is for.
 *
 * @function modified
 * @treturn integer the last modification time for the file.
 * @remark The returned value corresponds to the number of milliseconds elapsed
 * since the Unix Epoch.
 */
XX(modified)

#undef XX

#define XX(name)                                                   \
    static int fs_metadata_##name(lua_State *L)                    \
    {                                                              \
        void *ud = luaL_checkudata(L, 1, AttributesMetatableName); \
        lua_pushboolean(L, fsL_metadata_##name(ud));               \
        return 1;                                                  \
    }

/***
 * Gets a value indicating if the metadata are for a directory.
 *
 * @function is_directory
 * @treturn boolean `true` if the metadata are for a directory; otherwise `false`.
 */
XX(is_directory)

/***
 * Gets a value indicating if the metadata are for a regular file.
 *
 * @function is_file
 * @treturn boolean `true` if the metadata are for a regular file; otherwise `false`.
 */
XX(is_file)

/***
 * Gets a value indicating if the metadata are for a read-only file.
 *
 * @function is_readonly
 * @treturn boolean `true` if the metadata are for a read-only file; otherwise `false`.
 */
XX(is_readonly)

/***
 * Gets a value indicating if the metadata are for a symbolic link.
 *
 * @function is_symlink
 * @treturn boolean `true` if the metadata are for a symbolic link; otherwise `false`.
 */
XX(is_symlink)

#if defined(_STD_WINDOWS)
/***
 * Gets a value indicating if the metadata are for a hidden file or directory.
 *
 * @function is_hidden
 * @treturn boolean `true` if the metadata are for a hidden file or directory; otherwise `false`.
 * @remark Windows-only
 */
XX(is_hidden)
#else

/***
 * Gets a value indicating if the metadata are for a socket.
 *
 * @function is_socket
 * @treturn boolean `true` if the metadata are for a socket; otherwise `false`.
 * @remark Unix-only
 */
XX(is_socket)

/***
 * Gets a value indicating if the metadata are for a FIFO.
 *
 * @function is_fifo
 * @treturn boolean `true` if the metadata are for a FIFO; otherwise `false`.
 * @remark Unix-only
 */
XX(is_fifo)

/***
 * Gets a value indicating if the metadata are for a block device.
 *
 * @function is_block_device
 * @treturn boolean `true` if the metadata are for a block device; otherwise `false`.
 * @remark Unix-only
 */
XX(is_block_device)

/***
 * Gets a value indicating if the metadata are for a character device.
 *
 * @function is_char_device
 * @treturn boolean `true` if the metadata are for a character device; otherwise `false`.
 * @remark Unix-only
 */
XX(is_char_device)
#endif

#undef XX

/*** @section end */

/***
 * Returns a new userdata representing the metadata of a given path.
 *
 * @function metadata
 * @within Path functions
 * @tparam string path the path to get the attribute of,
 * @treturn Metadata the metadata of the given path; or `nil` if the function fails.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If `path` is `nil`.
 */
static int fs_metadata(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    if (fsL_metadata(L, path))
    {
        luaL_setmetatable(L, AttributesMetatableName);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static void create_metadata_metatable(lua_State *L)
{
    // clang-format off
    const struct luaL_Reg funcs[] = {
#define XX(name) {#name, fs_metadata_##name},
        XX(accessed)
        XX(created)
        XX(modified)
        XX(is_directory)
        XX(is_file)
        XX(is_readonly)
        XX(is_symlink)
#if defined(_STD_WINDOWS)
        XX(is_hidden)
#else
        XX(is_socket)
        XX(is_fifo)
        XX(is_block_device)
        XX(is_char_device)
#endif
        {NULL, NULL}
#undef XX
    };
    // clang-format on

    luaL_newmetatable(L, AttributesMetatableName); // mt
    luaL_newlibtable(L, funcs);                    // mt t
    luaL_setfuncs(L, funcs, 0);                    // mt t
    lua_setfield(L, -2, "__index");                // mt
    lua_pop(L, 1);                                 //
}
