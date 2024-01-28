#include "libfs.h"
#include "libfs_unix.h"
#include "libtime.h"

#include <dirent.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <errno.h>

#ifdef _STD_APPLE
#include <copyfile.h>
#include <removefile.h>
#endif

#ifdef _STD_APPLE
bool fsL_copy_file(lua_State *L, const char *src, const char *dst, bool overwrite)
{
    copyfile_state_t state = copyfile_state_alloc();
    copyfile_flags_t flags = COPYFILE_ALL;
    if (!overwrite) flags |= COPYFILE_EXCL;
    int r = copyfile(src, dst, state, flags);
    copyfile_state_free(state);
    return r == 0;
}
#else
bool fsL_copy_file(lua_State *L, const char *src, const char *dst, bool overwrite)
{
    bool result = false;

    int src_fd = open(src, O_RDONLY);
    if (src_fd == -1) goto ERROR;

    int flags = O_WRONLY | O_CREAT;
    if (!overwrite) flags |= O_EXCL;
    int dst_fd = open(dst, flags);
    if (dst_fd == -1) goto ERROR;

    char buf[8192];
    while(true)
    {
        ssize_t n = read(src_fd, buf, sizeof(buf));
        if (n == 0) break;
        if (n == -1 || write(dst_fd, buf, n) == -1) goto ERROR;
    }
    result = true;

ERROR:
    if (src_fd != -1) close(src_fd);
    if (dst_fd != -1) close(dst_fd);
    return result;
}
#endif

#ifdef _STD_APPLE
#include <removefile.h>
bool fsL_rename(lua_State *L, const char *from, const char *to, bool overwrite)
{
    return (overwrite ? rename(from, to) : renamex_np(from, to, RENAME_EXCL)) == 0;
}
#else
bool fsL_rename(lua_State *L, const char *from, const char *to, bool overwrite)
{
    return (overwrite ? rename(from, to) : renameat(AT_FDCWD, from, AT_FDCWD, to)) == 0;
}
#endif

bool fsL_create_directory(lua_State *L, const char *path)
{
    return mkdir(path, ACCESSPERMS) == 0;
}

#ifdef _STD_APPLE
static bool remove_directory(lua_State *L, const char *path, bool recursive)
{
    removefile_state_t state = removefile_state_alloc();
    removefile_flags_t flags = REMOVEFILE_SECURE_7_PASS;
    if (recursive) flags |= REMOVEFILE_RECURSIVE;
    int r = removefile(path, state, flags);
    removefile_state_free(state);
    return r == 0;
}

bool fsL_remove_directory(lua_State *L, const char *path)
{
    return remove_directory(L, path, false);
}

bool fsL_remove_file(lua_State *L, const char *path)
{
    removefile_state_t state = removefile_state_alloc();
    removefile_flags_t flags = REMOVEFILE_SECURE_7_PASS;
    int r = removefile(path, state, flags);
    removefile_state_free(state);
    return r == 0;
}
#else
bool fsL_remove_directory(lua_State *L, const char *path)
{
    return remove(path) == 0;
}

bool fsL_delete_file(lua_State *L, const char *path)
{
    return remove(path) == 0;
}
#endif

bool fsL_exists(lua_State *L, const char *path, bool *exists)
{
    struct stat st;
    int err = lstat(path, &st);
    *exists = err == 0;
    return err == 0 || err == ENOENT;
}

bool fsL_directory_exists(lua_State *L, const char *path, bool *exists)
{
    struct stat st;
    int err = lstat(path, &st);
    *exists = err == 0 && S_ISDIR(st.st_mode);
    return err == 0 || err == ENOENT;
}

bool fsL_file_exists(lua_State *L, const char *path, bool *exists)
{
    struct stat st;
    int err = lstat(path, &st);
    *exists = err  == 0 && S_ISREG(st.st_mode);
    return err == 0 || err == ENOENT;
}

bool fsL_file_length(lua_State *L, const char *path, lua_Integer *length)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *length = (lua_Integer)st.st_size;
    return true;
}

bool fsL_is_directory(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISDIR(st.st_mode);
    return true;
}

bool fsL_is_file(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISREG(st.st_mode);
    return true;
}

bool fsL_is_readonly(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISREG(st.st_mode);
    return true;
}

bool fsL_is_symlink(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISREG(st.st_mode);
    return true;
}

bool fsL_is_block_device(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISBLK(st.st_mode);
    return true;
}

bool fsL_is_char_device(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISCHR(st.st_mode);
    return true;
}

bool fsL_is_socket(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISSOCK(st.st_mode);
    return true;
}

bool fsL_is_fifo(lua_State *L, const char *path, bool *result)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    *result = S_ISFIFO(st.st_mode);
    return true;
}
