
#include "std.h"
#include "libpath.h"
#include "liballocator.h"
#include "libsyserror.h"

#if defined(_STD_WINDOWS)
#define strncasecmp _strnicmp
#include "libpath_win.c"
#else
#include "libpath_unix.c"
#endif

bool pathL_is_rooted(const char *path, size_t path_len, bool *verbatim)
{
    return pathL_root_length(path, path_len, verbatim) > 0;
}

bool pathL_is_valid_path(const char *path, size_t path_len)
{
    for (size_t i = path_len; i--;)
    {
        if (!is_valid_path_char(*path++)) return false;
    }
    return true;
}

bool pathL_is_valid_file_name(const char *path, size_t path_len)
{
    for (size_t i = path_len; i--;)
    {
        if (!is_valid_file_name_char(*path++)) return false;
    }
    return true;
}

bool pathL_is_empty(const char *path, size_t path_len)
{
    for (size_t i = path_len; i--;)
    {
        if (*path++ != ' ') return false;
    }
    return true;
}

int pathL_compare(const char *path, size_t path_len, const char *other_path, size_t other_path_len)
{
    if (path_len > other_path_len) return 1;
    if (path_len < other_path_len) return -1;
    return strncasecmp(path, other_path, path_len);
}

const char *pathL_checklpath(lua_State *L, int arg, size_t *size)
{
    size_t path_len;
    const char *path = luaL_checklstring(L, arg, &path_len);
    if (path_len > INT_MAX)
    {
        luaL_argerror(L, arg, "path too long");
    }
    if (!pathL_is_valid_path(path, path_len))
    {
        luaL_argerror(L, arg, "invalid path");
    }
    if (size != NULL) *size = path_len;
    return path;
}

const char *pathL_optlpath(lua_State *L, int arg, const char *def, size_t *size)
{
    size_t path_len;
    const char *path = luaL_optlstring(L, arg, NULL, &path_len);
    if (path == NULL) return NULL;

    if (path_len > INT_MAX)
    {
        luaL_argerror(L, arg, "path too long");
    }
    if (pathL_is_empty(path, path_len))
    {
        luaL_argerror(L, arg, "empty path");
    }
    if (!pathL_is_valid_path(path, path_len))
    {
        luaL_argerror(L, arg, "invalid path");
    }
    if (size != NULL) *size = path_len;
    return path;
}

path_components_t pathL_split_path(const char *path, size_t path_len)
{
    if (path_len == 0)
    {
        return (path_components_t) {0};
    }

    bool verbatim;
    size_t root_len = pathL_root_length(path, path_len, &verbatim);

    size_t file_offset = root_len;
    for (size_t i = path_len; --i > root_len;)
    {
        if (pathL_is_dirsep(path[i], verbatim))
        {
            file_offset = i + 1;
            break;
        }
    }

    size_t dir_len = file_offset;
    while (dir_len > root_len && pathL_is_dirsep(path[dir_len - 1], verbatim))
    {
        dir_len--;
    }

    size_t ext_offset = 0;
    for (size_t i = path_len; --i > file_offset + 1;)
    {
        if (path[i] == '.')
        {
            ext_offset = i + 1;
            break;
        }
    }

    path_components_t components;
    components.verbatim = verbatim;
    components.root_len = root_len;
    components.dir_len = dir_len;
    components.file_offset = file_offset;
    components.ext_offset = ext_offset;

    // printf("pathL_split_path path: %s\n", path);
    // printf("  verbatim: %d\n", verbatim);
    // printf("  root_len: %d\n", root_len);
    // printf("  dir_len: %d\n", dir_len);
    // printf("  file_offset: %d\n", file_offset);
    // printf("  ext_offset: %d\n", ext_offset);

    return components;
}

struct path_tokenizer
{
    const char *path;
    size_t remaining;
    bool verbatim;
};

path_tokenizer_t *path_tokenizer_new(lua_State *L, const char *path, size_t path_len, bool verbatim)
{
    for (; path_len && pathL_is_dirsep(*path, verbatim); path++, path_len--)
        ;
    for (; path_len && pathL_is_dirsep(path[path_len - 1], verbatim); path_len--)
        ;

    path_tokenizer_t *tokenizer = allocatorL_malloc(L, sizeof(path_tokenizer_t));
    tokenizer->path = path;
    tokenizer->remaining = path_len;
    tokenizer->verbatim = verbatim;
    return tokenizer;
}

void path_tokenizer_free(lua_State *L, path_tokenizer_t *tokenizer)
{
    allocatorL_free(L, tokenizer);
}

const char *path_tokenizer_next(path_tokenizer_t *tokenizer, size_t *token_length)
{
    bool verbatim = tokenizer->verbatim;
    size_t n = tokenizer->remaining;
    const char *p = tokenizer->path;

    *token_length = 0;
    const char *token = NULL;
    while (true)
    {
        for (; n && pathL_is_dirsep(*p, verbatim); p++, n--)
            ;

        if (!n) break;

        const char *q = p;
        for (; n && !pathL_is_dirsep(*p, verbatim); p++, n--)
            ;

        if (*q != '.' || p != q + 1 || n == 0 || verbatim)
        {
            token = q;
            *token_length = (size_t)(p - q);
            break;
        }
    }
    tokenizer->path = p;
    tokenizer->remaining = n;
    return token;
}

const char *path_tokenizer_next_back(path_tokenizer_t *tokenizer, size_t *token_length)
{
    bool verbatim = tokenizer->verbatim;
    size_t n = tokenizer->remaining;
    const char *p = tokenizer->path + n;

    *token_length = 0;
    const char *token = NULL;
    if (n == 0)
    {
        return NULL;
    }

    while (true)
    {
        for (; n && pathL_is_dirsep(p[-1], verbatim); p--, n--)
            ;

        if (!n) break;

        const char *q = p;
        for (; n && !pathL_is_dirsep(p[-1], verbatim); p--, n--)
            ;

        if (*p != '.' || q != p + 1 || n == 0 || verbatim)
        {
            token = p;
            *token_length = (size_t)(q - p);
            break;
        }
    }
    tokenizer->remaining = n;
    return token;
}
