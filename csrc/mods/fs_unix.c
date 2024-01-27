/***
 * @module std.fs
 */

#include "fs.h"
#include "libsyserror.h"
#include "libutil.h"

#include <lauxlib.h>
#include <string.h>

#define XX(name)                                   \
    static int fs_##name(lua_State *L)             \
    {                                              \
        const char *path = luaL_checkstring(L, 1); \
        bool result;                               \
        if (fsL_##name(L, path, &result))          \
        {                                          \
            lua_pushboolean(L, result);            \
            return 1;                              \
        }                                          \
        _STD_RETURN_NIL_ERROR                      \
    }

/***
 * Returns a value indicating whether a given existing path is a block device.
 *
 * @function is_block_device
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a block device, otherwise `false`.
 * @treturn string `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_block_device)

/***
 * Returns a value indicating whether a given existing path is a character device.
 *
 * @function is_char_device
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a character device, otherwise `false`.
 * @treturn string `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_char_device)

/***
 * Returns a value indicating whether a given existing path is a socket file.
 *
 * @function is_socket
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a socket file file, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_socket)

/***
 * Returns a value indicating whether a given existing path is a fifo file.
 *
 * @function is_fifo
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a fifo file file, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_fifo)

#undef XX
