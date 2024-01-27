#pragma once

#include <lua.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct
{
    size_t root_len;
    size_t dir_len;
    size_t file_offset;
    size_t ext_offset;
    bool verbatim;
} path_components_t;

int pathL_full_path(lua_State *L, const char *path, size_t path_len);
int pathL_root(lua_State *L, const char *path, size_t path_len);
int pathL_normalize(lua_State *L, const char *path, size_t path_len);
int pathL_canonicalize(lua_State *L, const char *path, size_t path_len);

bool pathL_is_fully_qualified(const char *path, size_t path_len);
bool pathL_is_dirsep(const char c, bool verbatim);
bool pathL_is_empty(const char *path, size_t path_len);
bool pathL_is_verbatim(const char *path, size_t path_len);
bool pathL_is_normalized(const char *path, size_t path_len);
bool pathL_is_rooted(const char *path, size_t path_len, bool *verbatim);
int pathL_compare(const char *path, size_t path_len, const char *other_path, size_t other_path_len);
size_t pathL_root_length(const char *path, size_t path_len, bool *verbatim);
path_components_t pathL_split_path(const char *path, size_t path_len);

bool pathL_is_valid_path(const char *path, size_t path_len);
bool pathL_is_valid_file_name(const char *path, size_t path_len);

void pathL_get_random_bytes(char *bytes);

const char *pathL_checklpath(lua_State *L, int arg, size_t *size);
const char *pathL_optlpath(lua_State *L, int arg, const char *def, size_t *size);

#define _PATH_CHECKLPATH(name, arg) \
    size_t name##_len;              \
    const char *name = pathL_checklpath(L, arg, &name##_len);

#define _PATH_OPTLPATH(name, arg, def) \
    size_t name##_len;                 \
    const char *name = pathL_optlpath(L, arg, def, &name##_len);

#define _PATH_CHECKPATH(name, arg) \
    const char *name = pathL_checklpath(L, arg, NULL);

#define _PATH_OPTPATH(name, arg, def) \
    const char *name = pathL_optlpath(L, arg, def, NULL);

typedef struct path_tokenizer path_tokenizer_t;
path_tokenizer_t *path_tokenizer_new(lua_State *L, const char *path, size_t path_len, bool verbatim);
void path_tokenizer_free(lua_State *L, path_tokenizer_t *tokenizer);

const char *path_tokenizer_next(path_tokenizer_t *tokenizer, size_t *token_length);
const char *path_tokenizer_next_back(path_tokenizer_t *tokenizer, size_t *token_length);
