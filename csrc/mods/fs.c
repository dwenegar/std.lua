/***
 * @module std.fs
 */

#include "fs.h"
#include "libsyserror.h"
#include "libutil.h"

#include <lauxlib.h>
#include <string.h>

#if defined(_STD_UNIX)
#include "fs_unix.c"
#else
#include "fs_win.c"
#endif

#include "fs_file.c"
#include "fs_dir.c"
#include "fs_meta.c"
#include "fs_entries.c"


/***
 * Changes the name of a file or directory.
 *
 * @function rename
 * @within File functions
 * @tparam string from the path of the file to move.
 * @tparam string to the path to the new location.
 * @tparam[boolean] overwrite `true` if the destination file can be overwritten; otherwise `false`.
 * @treturn boolean `true` if the function succeeded; otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why the function
 * failed.
 * @raise If `from` or `to` are `nil`.
 */
static int fs_rename(lua_State *L)
{
    const char *from = luaL_checkstring(L, 1);
    const char *to = luaL_checkstring(L, 2);
    int overwrite = lua_toboolean(L, 3);
    _STD_RETURN_OK_ERROR(fsL_rename(L, from, to, overwrite))
}

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
 * Returns a value indicating whether a given path exists.
 *
 * @function exists
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path exists, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise If `path` is `nil`.
 */
XX(exists)

/***
 * Returns a value indicating whether a given path exists and is a directory.
 *
 * @function directory_exists
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path exists and is a directory, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise If `path` is `nil`.
 */
XX(directory_exists)

/***
 * Returns a value indicating whether a given path exists and is a regular file.
 *
 * @function file_exists
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path exists and is a file, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise If `path` is `nil`.
 */
XX(file_exists)

/***
 * Returns a value indicating whether a given existing path is a symbolic link.
 *
 * @function is_symlink
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a symbolic link, otherwise `false`.
 * @treturn string `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_symlink)

/***
 * Returns a value indicating whether a given existing path is a directory.
 *
 * @function is_directory
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a directory, otherwise `false`.
 * @treturn string `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_directory)

/***
 * Returns a value indicating whether a given existing path is a regular file.
 *
 * @function is_file
 * @within Path functions
 * @tparam string path the path to test.
 * @treturn boolean `nil` if the function fails; `true` if the path is a regular file, otherwise `false`.
 * @treturn string err `nil` if the function succeeded; otherwise an error message describing why
 * the function failed.
 * @raise if `path` is `nil` or doesn't exists.
 */
XX(is_file)

#undef XX

#define XX(name)                          \
    static int fs_##name(lua_State *L)    \
    {                                     \
        _CHECKLSTRING(path, 1)            \
        lua_Integer result;               \
        if (fsL_##name(L, path, &result)) \
        {                                 \
            lua_pushinteger(L, result);   \
            return 1;                     \
        }                                 \
        _STD_RETURN_NIL_ERROR             \
    }

#undef XX

static int fs_is_windows(lua_State *L)
{
#if defined(_STD_WINDOWS)
    lua_pushboolean(L, 1);
#else
    lua_pushboolean(L, 0);
#endif
    return 1;
}

extern int luaopen_std_fs_native(lua_State *L)
{
    create_entries_metatable(L);
    create_metadata_metatable(L);

    // clang-format off
    const struct luaL_Reg funcs[] = {
    #define XX(name) { #name, fs_##name },
        XX(rename)
        XX(copy_file)

        XX(exists)
        XX(file_exists)
        XX(directory_exists)

        XX(is_file)
        XX(is_directory)
        XX(is_symlink)
#if defined(_STD_UNIX)
        XX(is_block_device)
        XX(is_char_device)
        XX(is_socket)
        XX(is_fifo)
#else
        XX(is_hidden)
#endif

        XX(create_directory)

        XX(remove_directory)
        XX(remove_file)

        XX(metadata)
        XX(entries)

        {NULL,NULL},
    #undef XX
    };
    // clang-format on

    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);
    return 1;
}
