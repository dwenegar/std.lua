#include "libfs.h"

#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>

typedef struct entries_s
{
    DIR *dir;
    bool closed;
} entries_t;

int read_dir_next(lua_State *L, void *ud)
{
    entries_t *entries = (entries_t *)ud;
    if (entries->closed) return 0;

    errno = 0;
    struct dirent *entry = readdir(entries->dir);
    if (entry != NULL)
    {
        lua_pushstring(L, entry->d_name);
        return 1;
    }
    if (errno != 0) return -1;
    closedir(entries->dir);
    entries->closed = true;
    return 0;
}

bool read_dir_close(lua_State *L, void *ud)
{
    entries_t *entries = (entries_t *)ud;
    if (!entries->closed && entries->dir != NULL)
    {
        return closedir(entries->dir) == 0;
    }
    return true;
}

bool fsL_read_dir(lua_State *L, const char *path)
{
    DIR *dir = opendir(path);
    if (dir == NULL) return false;

    entries_t *ud = (entries_t *)lua_newuserdata(L, sizeof(entries_t));
    if (ud == NULL)
    {
        closedir(dir);
        return false;
    }

    ud->closed = false;
    ud->dir = dir;
    return true;
}
