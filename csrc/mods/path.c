/***
 * Cross-platform path manipulation.
 *
 * @module std.path
 */
#include "libpath.h"
#include "liballocator.h"
#include "libutil.h"

#include <lauxlib.h>
#include <lua.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/***
 * Returns the extension of a path.
 * @function extension
 * @tparam string path the path from which to get the extension.
 * @treturn string the extension of the path; or `nil` if the path does not have
 * an extension.
 * @raise If `path` is `nil`.
 */
static int path_extension(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    const path_components_t components = pathL_split_path(path, path_len);
    if (components.ext_offset == 0 || components.ext_offset == path_len) return 0;
    lua_pushlstring(L, path + components.ext_offset, path_len - components.ext_offset);
    return 1;
}

/***
 * Returns a value that indicates whether a path includes a file name extension.
 * @function has_extension
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path includes a file name extension, otherwise
 * `false`.
 * @raise If `path` is `nil`.
 */
static int path_has_extension(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    const path_components_t components = pathL_split_path(path, path_len);
    lua_pushboolean(L, components.ext_offset != 0);
    return 1;
}

/***
 * Changes or remove the file name extension of a path.
 * @function set_extension
 * @tparam string path the path to modify.
 * @tparam[opt] string ext the new extension (with or without a leading period).
 * @treturn string the modified path.
 * @raise If `path` is `nil`.
 * @remark if `ext` is `nil` the function will return `path` with the file name
 * extension removed.
 */
static int path_set_extension(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _OPTLSTRING(ext, 2, NULL)

    if (path == NULL)
    {
        lua_pushnil(L);
        return 1;
    }

    if (path_len == 0)
    {
        lua_settop(L, 1);
        return 1;
    }

    path_components_t components = pathL_split_path(path, path_len);
    if (components.file_offset == path_len)
    {
        lua_settop(L, 1);
        return 1;
    }

    size_t stem_len = components.ext_offset ? components.ext_offset - 1 : path_len;

    if (ext_len == 0)
    {
        // "path.ext" -> "path"
        lua_pushlstring(L, path, stem_len);
    }
    else
    {
        // ".path" -> ".path.ext"
        // "path" -> "path.ext"
        luaL_Buffer b;
        luaL_buffinitsize(L, &b, stem_len + ext_len + 1);
        luaL_addlstring(&b, path, stem_len);
        luaL_addchar(&b, '.');
        luaL_addlstring(&b, ext, ext_len);
        luaL_pushresult(&b);
    }
    return 1;
}

/***
 * Returns the root directory information of a path.
 * @function root
 * @tparam string path the path from which to get the root path.
 * @treturn string the root directory of the specified path.
 * @raise If `path` is `nil`, empty, or invalid.
 */
static int path_root(lua_State *L)
{
    _PATH_CHECKLPATH(path, 1)

    if (path == NULL)
    {
        lua_pushnil(L);
        return 1;
    }

    if (path_len == 0)
    {
        lua_settop(L, 1);
        return 1;
    }

    const path_components_t components = pathL_split_path(path, path_len);
    if (components.root_len == 0) return 0;
    if (components.root_len == path_len)
    {
        lua_settop(L, 1);
    }
    else
    {
        lua_pushlstring(L, path, components.root_len);
    }
    return 1;
}

/***
 * Changes or remove the root directory information of a path.
 * @function set_root
 * @tparam string path the path to modify.
 * @tparam[opt] string root the new root.
 * @treturn string the modified path.
 * @raise If `path` is `nil`, empty, or invalid
 * @remark if `root` is `nil` the function will return `path` with the root part
 * removed.
 */
static int path_set_root(lua_State *L)
{
    _PATH_CHECKLPATH(path, 1)
    _PATH_CHECKLPATH(root, 2)

    const path_components_t components = pathL_split_path(path, path_len);

    if (components.root_len == path_len)
    {
        lua_settop(L, 2);
        return 1;
    }

    if (root != NULL || root_len == 0)
    {
        if (components.root_len == 0)
        {
            lua_settop(L, 1);
            return 1;
        }
    }

    path += components.root_len;
    path_len -= components.root_len;

    luaL_Buffer b;
    luaL_buffinitsize(L, &b, path_len + 1 + root_len);
    luaL_addlstring(&b, root, root_len);
    luaL_addchar(&b, _STD_PATH_DIRSEP);
    luaL_addlstring(&b, path, path_len);
    luaL_pushresult(&b);
    return 1;
}

/***
 * Returns the directory name part of a path.
 * @function parent
 * @tparam string path the path from which to get the directory name.
 * @treturn string the directory name part of `path`; or `nil` if `path` is
 * `nil`, empty, or denotes a root directory.
 * @raise If `path` is `nil`.
 */
static int path_parent(lua_State *L)
{
    _CHECKLSTRING(path, 1)

    const path_components_t components = pathL_split_path(path, path_len);
    if (components.root_len == path_len || components.dir_len == 0) return 0;
    lua_pushlstring(L, path, components.dir_len);
    return 1;
}

/***
 * Changes the directory part of a path.
 * @function set_parent
 * @tparam string path the path to modify.
 * @tparam string parent the new directory name.
 * @treturn string the modified path.
 * @raise If `path` or `parent` is `nil`.
 */
static int path_set_parent(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _CHECKLSTRING(parent, 2)

    path_components_t components = pathL_split_path(path, path_len);

    if (components.file_offset == path_len)
    {
        lua_settop(L, 2);
    }
    else if (parent_len == 0)
    {
        lua_pushlstring(L, path + components.file_offset, path_len - components.file_offset);
    }
    else
    {
        bool verbatim = pathL_is_verbatim(parent, parent_len);
        bool ends_with_sep = pathL_is_dirsep(parent[parent_len - 1], verbatim);
        size_t buf_size = parent_len + path_len - components.file_offset + (ends_with_sep ? 0 : 1);

        luaL_Buffer b;
        luaL_buffinitsize(L, &b, buf_size);
        luaL_addlstring(&b, parent, parent_len);
        if (!ends_with_sep) luaL_addchar(&b, _STD_PATH_DIRSEP);
        luaL_addlstring(&b, path + components.file_offset, path_len - components.file_offset);
        luaL_pushresult(&b);
    }
    return 1;
}

/***
 * Returns the file name part of a path.
 * @function file_name
 * @tparam string path the path from which to get the file name.
 * @treturn string the file name part of `path`.
 * @raise If `path` is `nil`.
 */
static int path_file_name(lua_State *L)
{
    _CHECKLSTRING(path, 1)

    const path_components_t components = pathL_split_path(path, path_len);
    size_t file_offset = components.file_offset;
    if (file_offset == path_len) return 0;

    if (file_offset == 0)
    {
        lua_settop(L, 1);
        return 1;
    }
    lua_pushlstring(L, path + file_offset, path_len - file_offset);
    return 1;
}

/***
 * Changes the file name part of a path.
 * @function set_file_name
 * @tparam string path the path to modify.
 * @tparam string file_name the new file name
 * @treturn string the modified path.
 * @raise If `path` or `file_name` is `nil`.
 */
static int path_set_file_name(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _CHECKLSTRING(file_name, 2)

    path_components_t components = pathL_split_path(path, path_len);

    if (components.file_offset == 0)
    {
        lua_settop(L, 2);
    }
    else if (file_name_len == 0)
    {
        lua_pushlstring(L, path, components.file_offset);
    }
    else
    {
        bool verbatim = components.verbatim;
        bool ends_with_sep = pathL_is_dirsep(path[components.file_offset - 1], verbatim);
        luaL_Buffer b;
        luaL_buffinitsize(L, &b, components.file_offset + file_name_len + (ends_with_sep ? 0 : 1));
        luaL_addlstring(&b, path, components.file_offset);
        if (!ends_with_sep) luaL_addchar(&b, _STD_PATH_DIRSEP);
        luaL_addlstring(&b, file_name, file_name_len);
        luaL_pushresult(&b);
    }
    return 1;
}

/***
 * Returns the file stem part (file name without extension) of a path.
 * @function file_stem
 * @tparam string path the path from which to get the file stem.
 * @treturn string the file stem part of `path`.
 * @raise If `path` is `nil`.
 */
static int path_file_stem(lua_State *L)
{
    _CHECKLSTRING(path, 1)

    const path_components_t components = pathL_split_path(path, path_len);
    if (components.file_offset == path_len) return 0;
    if (components.file_offset == 0 && components.ext_offset == path_len)
    {
        lua_settop(L, 1);
        return 1;
    }
    size_t stem_len = path_len - components.ext_offset + (components.ext_offset ? 1 : 0);
    lua_pushlstring(L, path + components.file_offset, stem_len);
    return 1;
}

/***
 * Changes the file stem part of a path.
 * @function set_file_stem
 * @tparam string path the path to modify.
 * @tparam[opt] string file_stem the new file stem.
 * @treturn string the modified path.
 * @raise If `path` or `file_stem` is `nil`.
 */
static int path_set_file_stem(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _CHECKLSTRING(file_stem, 2)

    path_components_t components = pathL_split_path(path, path_len);

    if (components.file_offset == 0)
    {
        lua_settop(L, 2);
    }
    else
    {
        bool verbatim = components.verbatim;
        bool ends_with_sep = pathL_is_dirsep(path[components.file_offset - 1], verbatim);
        size_t ext_len = path_len - components.ext_offset;
        size_t buf_size = components.file_offset + file_stem_len + (ends_with_sep ? 0 : 1) + ext_len;

        luaL_Buffer b;
        luaL_buffinitsize(L, &b, buf_size);
        luaL_addlstring(&b, path, components.file_offset);
        if (!ends_with_sep) luaL_addchar(&b, _STD_PATH_DIRSEP);
        luaL_addlstring(&b, file_stem, file_stem_len);
        if (ext_len > 0) luaL_addlstring(&b, path + components.ext_offset, ext_len);
        luaL_pushresult(&b);
    }
    return 1;
}

/***
 * Combines strings into a path.
 * @function combine
 * @tparam string ... the parts of the path.
 * @treturn string the combined parts.
 * @remark if any of the given args is an absolute path, the function will
 * combine the parts starting from that absolute path.
 */
static int path_combine(lua_State *L)
{
    int n = lua_gettop(L);
    if (n == 0) return 0;

    for (int i = 1; i <= n; i++)
    {
        luaL_checktype(L, i, LUA_TSTRING);
    }

    typedef struct
    {
        const char *path;
        size_t path_len;
        bool ends_with_sep;
    } arg_t;

    arg_t *args = allocatorL_allocT(L, arg_t, n);

    bool has_verbatim_root = false;
    size_t len = 0;
    int first = 0, last = 0;
    for (int i = 0; i < n; i++)
    {
        size_t path_len;
        const char *path = lua_tolstring(L, i + 1, &path_len);

        args[i].path = path;
        args[i].path_len = path_len;
        args[i].ends_with_sep = false;

        if (path_len == 0) continue;

        last = i;
        bool verbatim;
        if (pathL_is_rooted(path, path_len, &verbatim) && !has_verbatim_root)
        {
            first = i;
            len = 0;
            has_verbatim_root = verbatim;
        }

        len += path_len;
        if (pathL_is_dirsep(path[path_len - 1], verbatim))
        {
            len++;
            args[i].ends_with_sep = true;
        }
    }

    if (len == 0)
    {
        lua_pushlstring(L, "", 0);
        allocatorL_free(L, args);
        return 1;
    }

    luaL_Buffer b;
    luaL_buffinitsize(L, &b, len);
    for (int i = first; i <= last; i++)
    {
        arg_t arg = args[i];
        if (arg.path_len == 0) continue;

        luaL_addlstring(&b, arg.path, arg.path_len);
        if (i != last && !arg.ends_with_sep)
        {
            luaL_addchar(&b, _STD_PATH_DIRSEP);
        }
    }
    luaL_pushresult(&b);
    allocatorL_free(L, args);
    return 1;
}

/***
 * Returns a value that indicates whether a path contains a root.
 * @function is_rooted
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path contains a root; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_is_rooted(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    lua_pushboolean(L, pathL_is_rooted(path, path_len, NULL));
    return 1;
}

/***
 * Returns a value that indicates whether a path is fully qualified.
 * @function is_fully_qualified
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path is is fully qualified; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_is_fully_qualified(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    lua_pushboolean(L, pathL_is_fully_qualified(path, path_len));
    return 1;
}

/***
 * Returns a value that indicates whether a path is empty.
 * @function isempty
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path is empty; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_is_empty(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    lua_pushboolean(L, pathL_is_empty(path, path_len));
    return 1;
}

/***
 * Returns a value that indicates whether a path is valid.
 * @function is_valid_path
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path is valid; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_is_valid_path(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    lua_pushboolean(L, pathL_is_valid_path(path, path_len));
    return 1;
}

/***
 * Returns a value that indicates whether a path is a valid file name.
 * @function is_valid_file_name
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path is a valid file name; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_is_valid_file_name(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    lua_pushboolean(L, pathL_is_valid_file_name(path, path_len));
    return 1;
}

static bool is_valid_file_name_template(const char *template, const size_t template_len)
{
    for (size_t i = template_len; i-- > 0;)
    {
        if (*template ++ == 'X') return true;
    }
    return false;
}

/***
 * Returns a random folder name or file name.
 * @function random_file_name
 * @tparam[opt="rndXXXXXXXX"] string template the file name template to use.
 * the character `X` in the template is replaced with a random letter or digit.
 * @treturn string a random folder name or file name.
 * @raise If `template` is does not contain at least a `X`.
 */
static int path_random_file_name(lua_State *L)
{
    // clang-format off
    static char kFileChars[] = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    };
    // clang-format on

    _OPTLSTRING(template, 1, "rndXXXXXXXX")
    if (!is_valid_file_name_template(template, template_len))
    {
        return luaL_argerror(L, 1, "invalid template");
    }

    char *b = allocatorL_allocT(L, char, template_len);
    for (size_t i = 0; i < template_len; i++)
    {
        b[i] = template[i] != 'X' ? template[i] : kFileChars[rand() % sizeof(kFileChars)];
    }

    lua_pushlstring(L, b, template_len);
    allocatorL_free(L, b);
    return 1;
}

/***
 * Returns the absolute path for the specified path string.
 * @function full_path
 * @tparam string path the path for which to get the absolute path.
 * @tparam[opt] string base_path the base path to use when calculating the full path.
 * @treturn string the absolute path of `path`.
 * @raise If `path` is `nil`, empty, or invalid; or f `base_path` is invalid, or not fully qualified.
 * @remark if `base_path` is not `nil` returns the full path of the path obtained by combining `base_path` and `path`.
 */
static int path_full_path(lua_State *L)
{
    _PATH_CHECKLPATH(path, 1)
    _PATH_OPTLPATH(base_path, 2, NULL)

    if (base_path != NULL && !pathL_is_fully_qualified(base_path, base_path_len))
    {
        return luaL_argerror(L, 2, "path is not fully qualified");
    }

    if (pathL_is_fully_qualified(path, path_len))
    {
        return pathL_full_path(L, path, path_len);
    }

    if (base_path == NULL)
    {
        return pathL_full_path(L, path, path_len);
    }

    if (path_len == 0)
    {
        path = base_path;
        path_len = base_path_len;
    }
    else if (base_path_len > 0)
    {
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        luaL_addlstring(&b, base_path, base_path_len);
        luaL_addchar(&b, _STD_PATH_DIRSEP);
        luaL_addlstring(&b, path, path_len);
        luaL_pushresult(&b);

        path = lua_tolstring(L, -1, &path_len);
    }

    return pathL_full_path(L, path, path_len);
}

/***
 * Normalizes the directory separators in a path.
 * @function normalize
 * @tparam string path a path.
 * @treturn string `path` with the directory separators set to the platform's
 * native separator.
 * @raise If `path` is `nil`.
 */
static int path_normalize(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    if (pathL_is_normalized(path, path_len))
    {
        lua_settop(L, 1);
        return 1;
    }
    return pathL_normalize(L, path, path_len);
}

/***
 * Normalizes the canonical form of a path.
 * @function canonicalize
 * @tparam string path a path.
 * @treturn string `path` with the directory separators set to the platform's
 * native separator.
 * @raise If `path` is `nil`.
 */
static int path_canonicalize(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    if (path_len == 0)
    {
        lua_settop(L, 1);
        return 1;
    }
    return pathL_canonicalize(L, path, path_len);
}

/***
 * Returns a value that indicates whether the character at the specified
 * position in a path is a directory separator.
 * @function is_separator
 * @tparam string path the path to test.
 * @tparam integer index the position to test.
 * @treturn boolean `true` if the character at the specified position is a
 * @raise If `path` is `nil`.
 * directory separator; otherwise `false`.
 */
static int path_is_separator(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    size_t index = utilL_normalize_index(luaL_checkinteger(L, 2), path_len);

    if (path_len == 0)
    {
        lua_pushboolean(L, 0);
        return 1;
    }
    bool verbatim = pathL_is_verbatim(path, path_len);
    lua_pushboolean(L, pathL_is_dirsep(path[index - 1], verbatim));
    return 1;
}

/**
 * Breaks a path into directory and filename.
 * @function split
 * @tparam string path the path to split.
 * @treturn string the directory name part of the path.
 * @treturn string the file name part of the path.
 * @raise If `path` is `nil`.
 * @remark returns `nil` if `path` is `nil`.
 */
static int path_split(lua_State *L)
{
    _CHECKLSTRING(path, 1)

    if (path_len == 0) return 0;

    const path_components_t components = pathL_split_path(path, path_len);
    if (components.dir_len > 0)
    {
        lua_pushlstring(L, path, components.dir_len);
    }
    else
    {
        lua_pushnil(L);
    }
    if (components.file_offset == path_len) return 1;
    lua_pushlstring(L, path + components.file_offset, path_len - components.file_offset);
    return 2;
}

/**
 * Returns a value that indicates whether a path starts with the prefix suffix.
 * @function ends_with
 * @tparam string path the path to test.
 * @tparam string prefix the suffix to test for.
 * @treturn boolean `true` if the path starts with the specified prefix; otherwise `false`.
 * @raise If `path` or `prefix` is `nil`.
 * @remark matching is performed component-wise.
 */
static int path_starts_with(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _CHECKLSTRING(prefix, 2)

    if (path_len == 0 || prefix_len == 0)
    {
        lua_pushboolean(L, path_len == prefix_len);
        return 1;
    }

    bool path_verbatim;
    size_t path_root_len = pathL_root_length(path, path_len, &path_verbatim);

    bool prefix_verbatim;
    size_t prefix_root_len = pathL_root_length(prefix, prefix_len, &prefix_verbatim);

    if (pathL_compare(path, path_root_len, prefix, prefix_root_len) != 0)
    {
        lua_pushboolean(L, 0);
        return 1;
    }

    path += path_root_len;
    path_len -= path_root_len;
    path_tokenizer_t *path_tokenizer = path_tokenizer_new(L, path, path_len, path_verbatim);

    prefix += prefix_root_len;
    prefix_len -= prefix_root_len;
    path_tokenizer_t *prefix_tokenizer = path_tokenizer_new(L, prefix, prefix_len, prefix_verbatim);

    int result = 0;
    while (true)
    {
        size_t path_tok_len;
        const char *path_tok = path_tokenizer_next(path_tokenizer, &path_tok_len);
        size_t prefix_tok_len;
        const char *prefix_tok = path_tokenizer_next(prefix_tokenizer, &prefix_tok_len);

        if (path_tok_len == 0 || prefix_tok_len == 0)
        {
            result = path_tok_len == prefix_tok_len;
            break;
        }

        if (pathL_compare(path_tok, path_tok_len, prefix_tok, prefix_tok_len) != 0)
        {
            break;
        }
    }
    path_tokenizer_free(L, path_tokenizer);
    path_tokenizer_free(L, prefix_tokenizer);
    lua_pushboolean(L, result);
    return 1;
}

/**
 * Returns a value that indicates whether a path ends with the specified suffix.
 * @function ends_with
 * @tparam string path the path to test.
 * @tparam string suffix the suffix to test for.
 * @treturn boolean `true` if the path ends with the specified suffix; otherwise `false`.
 * @raise If `path` or `suffix` is `nil`.
 * @remark matching is performed component-wise.
 */
static int path_ends_with(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    _CHECKLSTRING(suffix, 2)

    if (path_len == 0 || suffix_len == 0)
    {
        lua_pushboolean(L, suffix_len == 0);
        return 1;
    }

    bool path_verbatim;
    size_t path_root_len = pathL_root_length(path, path_len, &path_verbatim);

    bool suffix_verbatim;
    size_t suffix_root_len = pathL_root_length(suffix, suffix_len, &suffix_verbatim);

    if (pathL_compare(path, path_root_len, suffix, suffix_root_len) != 0)
    {
        lua_pushboolean(L, 0);
        return 1;
    }

    path += path_root_len;
    path_len -= path_root_len;
    path_tokenizer_t *path_tokenizer = path_tokenizer_new(L, path, path_len, path_verbatim);

    suffix += suffix_root_len;
    suffix_len -= suffix_root_len;
    path_tokenizer_t *suffix_tokenizer = path_tokenizer_new(L, suffix, suffix_len, suffix_verbatim);

    int result = 0;
    while (true)
    {
        size_t path_tok_len;
        const char *path_tok = path_tokenizer_next_back(path_tokenizer, &path_tok_len);
        size_t suffix_tok_len;
        const char *suffix_tok = path_tokenizer_next_back(suffix_tokenizer, &suffix_tok_len);

        if (path_tok_len == 0 && suffix_tok_len == 0)
        {
            continue;
        }

        if (path_tok_len == 0 || suffix_tok_len == 0)
        {
            result = suffix_tok_len == 0;
            break;
        }

        if (pathL_compare(path_tok, path_tok_len, suffix_tok, suffix_tok_len) != 0)
        {
            result = 0;
            break;
        }
    }
    path_tokenizer_free(L, path_tokenizer);
    path_tokenizer_free(L, suffix_tokenizer);
    lua_pushboolean(L, result);
    return 1;
}

/**
 * Removes the ending directory separator from a given path.
 * @function trim_ending_separator
 * @tparam string path the path to modify.
 * @treturn string the modified path.
 * @raise If `path` is `nil`.
 */
static int path_trim_ending_separator(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    if (path_len == 0)
    {
        lua_settop(L, 1);
        return 1;
    }

    bool verbatim;
    size_t root_len = pathL_root_length(path, path_len, &verbatim);
    if (path_len == root_len || !pathL_is_dirsep(path[path_len - 1], verbatim))
    {
        lua_settop(L, 1);
        return 1;
    }

    lua_pushlstring(L, path, path_len - 1);
    return 1;
}

/**
 * Returns a value that indicates whether a path ends with a separator.
 * @function ends_with_separator
 * @tparam string path the path to test.
 * @treturn boolean `true` if the path ends with a separator; otherwise `false`.
 * @raise If `path` is `nil`.
 */
static int path_ends_with_separator(lua_State *L)
{
    _CHECKLSTRING(path, 1)
    if (path_len > 0)
    {
        bool verbatim = pathL_is_verbatim(path, path_len);
        lua_pushboolean(L, pathL_is_dirsep(path[path_len - 1], verbatim));
        return 1;
    }

    lua_pushboolean(L, 0);
    return 1;
}

/***
 * The system's directory separator.
 * @tfield string DIRSEP the system's directory separator.
 */

/***
 * An alternative directory separator.
 * @tfield string ALTDIRSEP the system's directory separator.
 */

/***
 * The system' path separator.
 * @tfield string PATHSEP the system's path separator.
 */

_STD_EXTERN int luaopen_std_path(lua_State *L)
{
    // clang-format off
    const struct luaL_Reg funcs[] =
    {
#define XX(name) { #name, path_ ## name },
        XX(canonicalize)
        XX(combine)
        XX(ends_with_separator)
        XX(ends_with)
        XX(extension)
        XX(file_name)
        XX(file_stem)
        XX(full_path)
        XX(has_extension)
        XX(is_empty)
        XX(is_fully_qualified)
        XX(is_rooted)
        XX(is_separator)
        XX(is_valid_file_name)
        XX(is_valid_path)
        XX(normalize)
        XX(parent)
        XX(random_file_name)
        XX(root)
        XX(set_extension)
        XX(set_file_name)
        XX(set_file_stem)
        XX(set_parent)
        XX(set_root)
        XX(split)
        XX(starts_with)
        XX(trim_ending_separator)
        { NULL, NULL }
#undef XX
    };
    // clang-format on

    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);

    char c = _STD_PATH_DIRSEP;
    lua_pushlstring(L, &c, sizeof(c));
    lua_setfield(L, -2, "DIRSEP");
    c = _STD_PATH_ALTDIRSEP;
    lua_pushlstring(L, &c, sizeof(c));
    lua_setfield(L, -2, "ALTDIRSEP");
    c = _STD_PATH_PATHSEP;
    lua_pushlstring(L, &c, sizeof(c));
    lua_setfield(L, -2, "PATHSEP");
    return 1;
}
