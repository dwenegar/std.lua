#include "libsyserror.h"
#include "liballocator.h"
#include "libos.h"

#include <errno.h>
#include <limits.h>
#include <locale.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#if defined(_STD_APPLE)
#include <libproc.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/vm_statistics.h>
#include <sys/sysctl.h>
#else
#include <fcntl.h>
#include <linux/limits.h>
#include <linux/sysctl.h>
#endif

static int system_memory_total(lua_State *L)
{
#if defined(_STD_APPLE)
    int mib[2] = {CTL_HW, HW_MEMSIZE};

    int64_t size;
    size_t len = sizeof(size);
    if (sysctl(mib, 2, &size, &len, NULL, 0) == 0)
    {
        lua_pushinteger(L, size);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
#else
    long page_size = sysconf(_SC_PAGESIZE);
    if (page_size == -1) goto ERROR;

    long npages = sysconf(_SC_PHYS_PAGES);
    if (npages == -1) goto ERROR;

    lua_pushinteger(L, (lua_Integer)(npages * page_size));
    return 1;

ERROR:
    _STD_RETURN_NIL_ERROR
#endif
}

static int system_memory_free(lua_State *L)
{
#if defined(_STD_APPLE)
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    mach_port_t port = mach_host_self();
    if (host_statistics(port, HOST_VM_INFO, (host_info_t)&vm_stat, &size) == KERN_SUCCESS)
    {
        vm_size_t page_size;
        mach_port_t port = mach_host_self();
        if (host_page_size(port, &page_size) == KERN_SUCCESS)
        {
            lua_pushinteger(L, vm_stat.active_count * page_size);
            return 1;
        }
    }
    _STD_RETURN_NIL_ERROR
#else
    long page_size = sysconf(_SC_PAGESIZE);
    if (page_size == -1) goto ERROR;

    long npages = sysconf(_SC_AVPHYS_PAGES);
    if (npages == -1) goto ERROR;

    lua_pushinteger(L, (lua_Integer)(npages * page_size));
    return 1;
ERROR:
    _STD_RETURN_NIL_ERROR
#endif
}

static int system_memory_used(lua_State *L)
{
    struct rusage usage;
    if (getrusage(RUSAGE_SELF, &usage) == 0)
    {
        lua_pushinteger(L, (lua_Integer)1024 * usage.ru_maxrss);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_cpu_count(lua_State *L)
{
    long ncpu = sysconf(_SC_NPROCESSORS_CONF);
    if (ncpu > 0)
    {
        lua_pushinteger(L, (lua_Integer)ncpu);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_version(lua_State *L)
{
    struct utsname name;
    if (!uname(&name))
    {
        lua_pushstring(L, name.release);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_user_home(lua_State *L)
{
    const char *value;
    if (!osL_get_env(L, "HOME", &value))
    {
        _STD_RETURN_NIL_ERROR
    }

    if (value != NULL && *value)
    {
        lua_pushstring(L, value);
        return 1;
    }

    uid_t uid = getuid();
    errno = 0;
    struct passwd *pwd = getpwuid(uid);
    if (pwd != NULL)
    {
        lua_pushstring(L, pwd->pw_dir);
        return 1;
    }
    if (errno == 0) return 0;
    _STD_RETURN_NIL_ERROR
}

static int system_user_name(lua_State *L)
{
    const char *value;
    if (!osL_get_env(L, "USER", &value))
    {
        _STD_RETURN_NIL_ERROR
    }

    if (value != NULL && strlen(value) > 0)
    {
        lua_pushstring(L, value);
        return 1;
    }

    if (!osL_get_env(L, "LOGNAME", &value))
    {
        _STD_RETURN_NIL_ERROR
    }

    if (value != NULL && strlen(value) > 0)
    {
        lua_pushstring(L, value);
        return 1;
    }

    uid_t uid = getuid();
    errno = 0;
    struct passwd *pwd = getpwuid(uid);
    if (pwd != NULL)
    {
        lua_pushstring(L, pwd->pw_name);
        return 1;
    }
    if (errno == 0) return 0;
    _STD_RETURN_NIL_ERROR
}

static int system_hostname(lua_State *L)
{
    char b[64 + 1];
    if (!gethostname(b, sizeof(b)))
    {
        lua_pushstring(L, b);
        return 1;
    }
    _STD_RETURN_NIL_ERROR
}

static int system_locale(lua_State *L)
{
    setlocale(LC_ALL, "");
    const char *locale = setlocale(LC_MESSAGES, NULL);
    if (locale == NULL)
    {
        _STD_RETURN_NIL_ERROR
    }
    char *tmp = allocatorL_alloc(L, strlen(locale) + 1);
    strcpy(tmp, locale);

    char *p = strchr(tmp, '.');
    if (p != NULL) *p = '\0';

    p = strchr(tmp, '@');
    if (p != NULL) *p = '\0';

    lua_pushstring(L, tmp);
    allocatorL_free(L, tmp);
    return 1;
}

static int system_process_name(lua_State *L)
{
#if defined(_STD_APPLE)
    char tmp[PROC_PIDPATHINFO_MAXSIZE];
    int pid = getpid();
    proc_pidpath(pid, tmp, PROC_PIDPATHINFO_MAXSIZE);
    lua_pushstring(L, tmp);
    allocatorL_free(L, tmp);
    return 1;
#else
    char *tmp = allocatorL_allocT(L, char, PATH_MAX);
    ssize_t tmp_len = readlink("/proc/self/exe", tmp, PATH_MAX);
    if (tmp_len == -1)
    {
        allocatorL_free(L, tmp);
        _STD_RETURN_NIL_ERROR
    }
    lua_pushlstring(L, tmp, tmp_len);
    allocatorL_free(L, tmp);
    return 1;
#endif
}

static int system_close(lua_State *L)
{
    (void)L;
    return 1;
}

static void system_init(lua_State *L)
{
    (void)L;
}
