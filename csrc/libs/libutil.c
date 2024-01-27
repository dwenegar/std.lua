#include "libutil.h"

size_t utilL_normalize_index(lua_Integer index, size_t len)
{
    if (index > 0)
    {
        return (size_t)index;
    }
    if (index == 0 || index < -(lua_Integer)len)
    {
        return 1;
    }
    return len + (size_t)index + 1;
}
