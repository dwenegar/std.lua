#include "std.h"
#include "libpath.h"

#include "liballocator.h"
#include "libsyserror.h"

#include <assert.h>
#include <ctype.h>
#include <lauxlib.h>
#include <stdbool.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/param.h>

#define BUF_SIZE 1024

static inline bool is_valid_file_name_char(const char c)
{
    return c != '\0' && c != '/';
}

static inline bool is_valid_path_char(const char c)
{
    return c != '\0';
}

bool pathL_is_dirsep(const char c, bool verbatim)
{
    return c == _STD_PATH_DIRSEP;
}

bool pathL_is_verbatim(const char *path, size_t path_len)
{
    return false;
}

size_t pathL_root_length(const char *path, size_t path_len, bool *verbatim)
{
    if (verbatim) *verbatim = false;
    return path_len > 0 && pathL_is_dirsep(*path, false) ? 1 : 0;
}

int pathL_is_absolute(const char *path, size_t path_len)
{
    return pathL_root_length(path, path_len, NULL) == 1;
}

bool pathL_is_normalized(const char *path, size_t path_len)
{
    for (size_t i = 1; i < path_len; i++)
    {
        if (pathL_is_dirsep(path[i], false) && pathL_is_dirsep(path[i - 1], false))
        {
            return false;
        }
    }
    return true;
}

bool pathL_is_partially_qualified(const char *path, size_t path_len)
{
    return !pathL_is_rooted(path, path_len, false);
}

bool pathL_is_fully_qualified(const char *path, size_t path_len)
{
    return !pathL_is_partially_qualified(path, path_len);
}

static bool push_cwd(lua_State *L)
{
    char b[BUF_SIZE];
    if (getcwd(b, BUF_SIZE))
    {
        lua_pushstring(L, b);
        return true;
    }
    if (errno != ERANGE) return false;

    size_t tmp_len = BUF_SIZE;
    while (true)
    {
        tmp_len *= 2;
        char *tmp = allocatorL_allocT(L, char, tmp_len);
        if (getcwd(tmp, tmp_len))
        {
            lua_pushstring(L, tmp);
            allocatorL_free(L, tmp);
            return true;
        }
        if (errno != ERANGE)
        {
            allocatorL_free(L, tmp);
            return false;
        }
        allocatorL_free(L, tmp);
    }
}

int pathL_full_path(lua_State *L, const char *path, size_t path_len)
{
    if (!pathL_is_rooted(path, path_len, NULL))
    {
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        if (!push_cwd(L))
        {
            _STD_RETURN_NIL_ERROR;
        }
        luaL_addvalue(&b);
        luaL_addchar(&b, _STD_PATH_DIRSEP);
        luaL_addlstring(&b, path, path_len);
        luaL_pushresult(&b);

        path = lua_tolstring(L, -1, &path_len);
    }

    size_t root_len = pathL_root_length(path, path_len, NULL);
    assert(root_len > 0);

    size_t tmp_len = 0;
    char *tmp = allocatorL_allocT(L, char, path_len);
    memset(tmp, 0, path_len);

    size_t skip = root_len;
    if (pathL_is_dirsep(path[skip - 1], false))
    {
        skip--;
    }

    for (size_t i = 0; i < skip; i++)
    {
        tmp[tmp_len++] = path[i];
    }

    // printf("  skip %zd\n", skip);
    // printf("  tmp_len %zd\n", tmp_len);

    for (size_t i = skip; i < path_len; i++)
    {
        char c = path[i];
        if (pathL_is_dirsep(c, false) && i + 1 < path_len)
        {
            // skip //
            if (pathL_is_dirsep(path[i + 1], false)) continue;

            // skip /./
            if ((i + 2 == path_len || pathL_is_dirsep(path[i + 2], false)) && path[i + 1] == '.')
            {
                i++;
                continue;
            }

            // rewind on /../
            if (i + 2 < path_len && (i + 3 == path_len || pathL_is_dirsep(path[i + 3], false)) && path[i + 1] == '.'
                && path[i + 2] == '.')
            {
                size_t new_tmp_len = skip;
                for (size_t j = tmp_len; j-- > root_len;)
                {
                    if (pathL_is_dirsep(tmp[j], false))
                    {
                        new_tmp_len = j;
                        break;
                    }
                }

                tmp_len = new_tmp_len < skip ? skip : new_tmp_len;
                // printf("    tmp_len %zd\n", tmp_len);

                i += 2;
                continue;
            }

            tmp[tmp_len++] = c;
            continue;
        }

        tmp[tmp_len++] = c;
    }
    if (skip != root_len && tmp_len < root_len)
    {
        tmp[tmp_len++] = path[root_len - 1];
    }

    lua_pushlstring(L, tmp, tmp_len);
    allocatorL_free(L, tmp);
    return 1;
}

int pathL_normalize(lua_State *L, const char *path, size_t path_len)
{
    if (pathL_is_normalized(path, path_len))
    {
        lua_settop(L, 1);
        return 1;
    }

    size_t tmp_len = 0;
    char *tmp = allocatorL_allocT(L, char, path_len);
    bool skip_sep = 0;
    for (size_t i = 0; i < path_len; i++)
    {
        if (!pathL_is_dirsep(path[i], false))
        {
            skip_sep = false;
            tmp[tmp_len++] = path[i];
        }
        else if (!skip_sep)
        {
            skip_sep = true;
            tmp[tmp_len++] = path[i];
        }
    }
    lua_pushlstring(L, tmp, tmp_len);
    allocatorL_free(L, tmp);
    return 1;
}

int pathL_canonicalize(lua_State *L, const char *path, size_t path_len)
{
    char b[MAXPATHLEN];
    if (realpath(path, b))
    {
        lua_pushstring(L, b);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}
