#include "std.h"
#include "libtime.h"

#include <lauxlib.h>
#include <userenv.h>

void sleepL_sleep(lua_Integer millis)
{
    Sleep((DWORD)millis);
}
