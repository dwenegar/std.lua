#include "libfs.h"
#include "libtime.h"

#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>


bool fsL_metadata(lua_State *L, const char *path)
{
    struct stat st;
    if (lstat(path, &st)) return false;
    void *ud = lua_newuserdata(L, sizeof(st));
    if (ud == NULL) return false;
    memcpy(ud, &st, sizeof(st));
    return true;
}

lua_Integer fsL_metadata_length(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return st->st_size;
}

lua_Integer fsL_metadata_accessed(void *ud)
{
    struct stat *st = (struct stat *)ud;
#ifdef _STD_APPLE
    return timespec_to_millis(st->st_atimespec);
#else
    return timespec_to_millis(st->st_atim);
#endif
}

lua_Integer fsL_metadata_modified(void *ud)
{
    struct stat *st = (struct stat *)ud;
#ifdef _STD_APPLE
    return timespec_to_millis(st->st_mtimespec);
#else
    return timespec_to_millis(st->st_mtim);
#endif
}

lua_Integer fsL_metadata_created(void *ud)
{
    struct stat *st = (struct stat *)ud;
#ifdef _STD_APPLE
    return timespec_to_millis(st->st_ctimespec);
#else
    return timespec_to_millis(st->st_ctim);
#endif
}

bool fsL_metadata_is_directory(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISDIR(st->st_mode);
}

bool fsL_metadata_is_file(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISREG(st->st_mode);
}

bool fsL_metadata_is_symlink(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISLNK(st->st_mode);
}

bool fsL_metadata_is_readonly(void *ud)
{
    struct stat *st = (struct stat *)ud;
    const mode_t write_mask = S_IWUSR | S_IWGRP | S_IWOTH;
    return (st->st_mode & write_mask) == 0;
}

bool fsL_metadata_is_block_device(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISBLK(st->st_mode);
}

bool fsL_metadata_is_char_device(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISCHR(st->st_mode);
}

bool fsL_metadata_is_socket(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISSOCK(st->st_mode);
}

bool fsL_metadata_is_fifo(void *ud)
{
    struct stat *st = (struct stat *)ud;
    return S_ISFIFO(st->st_mode);
}
