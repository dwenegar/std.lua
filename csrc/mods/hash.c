//  Copyright Simone Livieri. All Rights Reserved.
//  Unauthorized copying of this file, via any medium is strictly prohibited.
//  For terms of use, see LICENSE.txt

/***
 * @module std.hash
 */

#include <lauxlib.h>
#include <stdint.h>
#include <math.h>

/***
 * Returns a 32 bits hash code for a given value.
 * If the given value has a metatable defining the `__hash` metamethod,
 * that method will be used to calculate the value's hash code.
 * @function hash
 * @param value the value to compute the hash code of.
 * @treturn integer a 32 bits hash code for the given value.
 */
static int hash_hash(lua_State *L)
{
    int type = lua_type(L, 1);
    if (type == LUA_TNONE || type == LUA_TNIL)
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    if (lua_getmetatable(L, 1)) // mt
    {
        if (lua_getfield(L, -1, "__hash") == LUA_TFUNCTION) // mt __hash
        {
            lua_pushvalue(L, 1); // mt __hash value
            lua_call(L, 1, 1);   // mt hash
            lua_remove(L, -2);   // hash
            return 1;
        }
        lua_pop(L, 1);
    }

    if (type == LUA_TBOOLEAN)
    {
        int hash = lua_toboolean(L, 1);
        lua_pushinteger(L, hash);
        return 1;
    }

    if (type == LUA_TSTRING)
    {
        size_t len;
        const char *s = luaL_checklstring(L, 1, &len);

        // use up to 64 characters to compute the hash
        const size_t step = (len >> 6) + 1;
        uint32_t hash = (uint32_t)(len ^ (len >> 32));
        for (size_t i = 0; i < len; i += step)
        {
            hash = (hash << 2) + (hash >> 2) + (uint32_t)s[i];
        }
        lua_pushinteger(L, (lua_Integer)hash);
        return 1;
    }

    if (type == LUA_TNUMBER)
    {
        int is_num;
        uint64_t bits = (uint64_t)lua_tointegerx(L, 1, &is_num);
        if (!is_num)
        {
            double n = (double)lua_tonumber(L, 1);
            bits = isnan(n) ? 0x7ff8000000000000L : *(uint64_t *)&n;
        }
        lua_pushinteger(L, (lua_Integer)(uint32_t)(bits ^ (bits >> 32)));
        return 1;
    }

    uint64_t bits = (uint64_t)lua_topointer(L, 1);
    lua_pushinteger(L, (lua_Integer)(uint32_t)(bits ^ (bits >> 32)));
    return 1;
}

// clang-format off
static const struct luaL_Reg funcs[] =
{
    { "hash", hash_hash },
    { NULL, NULL }
};
// clang-format on

extern int luaopen_std_hash(lua_State *L)
{
    lua_newtable(L);
    luaL_setfuncs(L, funcs, 0);
    return 1;
}
