#pragma once

#include "std.h"

#include <lauxlib.h>
#include <lua.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct open_opts_s
{
    bool read : 1;
    bool write : 1;
    bool append : 1;
    bool truncate : 1;
    bool create : 1;
    bool exclusive : 1;
} open_opts_t;

bool fsL_rename(lua_State *L, const char *src, const char *dst, bool overwrite);
bool fsL_copy_file(lua_State *L, const char *src, const char *dst, bool overwrite);

bool fsL_link(lua_State *L, const char *src, const char *dst);

bool fsL_create_directory(lua_State *L, const char *path);
bool fsL_remove_directory(lua_State *L, const char *path);
bool fsL_remove_file(lua_State *L, const char *path);

bool fsL_directory_exists(lua_State *L, const char *path, bool *exists);
bool fsL_file_exists(lua_State *L, const char *path, bool *exists);
bool fsL_exists(lua_State *L, const char *path, bool *exists);

bool fsL_is_directory(lua_State *L, const char *path, bool *result);
bool fsL_is_file(lua_State *L, const char *path, bool *result);
bool fsL_is_readonly(lua_State *L, const char *path, bool *result);
bool fsL_is_symlink(lua_State *L, const char *path, bool *result);

#if defined(_STD_WINDOWS)
bool fsL_is_hidden(lua_State *L, const char *path, bool *result);
#else
bool fsL_is_block_device(lua_State *L, const char *path, bool *result);
bool fsL_is_char_device(lua_State *L, const char *path, bool *result);
bool fsL_is_socket(lua_State *L, const char *path, bool *result);
bool fsL_is_fifo(lua_State *L, const char *path, bool *result);
#endif

// userdata

// metadata
bool fsL_metadata(lua_State *L, const char *path);

lua_Integer fsL_metadata_length(void *ud);
lua_Integer fsL_metadata_accessed(void *ud);
lua_Integer fsL_metadata_modified(void *ud);
lua_Integer fsL_metadata_created(void *ud);

bool fsL_metadata_is_directory(void *ud);
bool fsL_metadata_is_file(void *ud);
bool fsL_metadata_is_readonly(void *ud);
bool fsL_metadata_is_symlink(void *ud);
#if defined(_STD_WINDOWS)
bool fsL_metadata_is_hidden(void *ud);
#else
bool fsL_metadata_is_block_device(void *ud);
bool fsL_metadata_is_char_device(void *ud);
bool fsL_metadata_is_socket(void *ud);
bool fsL_metadata_is_fifo(void *ud);
#endif

// entries
bool fsL_read_dir(lua_State *L, const char *path);
int read_dir_next(lua_State *L, void *ud);
bool read_dir_close(lua_State *L, void *ud);
