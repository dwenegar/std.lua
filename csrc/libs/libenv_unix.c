#include "libenv.h"
#include "liballocator.h"
#include "libsyserror.h"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>

bool envL_get_current_dir(lua_State *L)
{
    char buf[PATH_MAX];
    if (getcwd(buf, sizeof(buf)) == NULL) return false;
    lua_pushstring(L, buf);
    return true;
}

bool envL_set_current_dir(lua_State *L, const char *path)
{
    return chdir(path) == 0;
}

bool envL_get_var(lua_State *L, const char *name)
{
    *value = getenv(name);
    return errno == 0;
}

bool envL_set_var(lua_State *L, const char *name, const char *value)
{
    return setenv(name, value, 1) == 0;
}

extern char **environ;

bool envL_get_vars(lua_State *L)
{
    char **p = environ;

    lua_newtable(L); // env
    while (p != NULL && *p != NULL)
    {
        const char *q = *p;
        const char *eq = strchr(q, '=');
        if (eq != NULL)
        {
            lua_pushlstring(L, q, eq - q);
            lua_pushstring(L, eq + 1);
            lua_settable(L, -3);
        }

        p++;
    }

    return true;
}
