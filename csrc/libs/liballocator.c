#include "liballocator.h"

#include <assert.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

size_t __liballocator_size;

#define _LIBALLOCATOR_SIZE_MAX (SIZE_MAX >> 1)

size_t allocatorL_check_size(lua_State *L, size_t size)
{
    if (size == 0) return 0;
    if (size > _LIBALLOCATOR_SIZE_MAX - _LIBALLOCATOR_HEADER_SIZE)
    {
        luaL_error(L, "memory allocation error: block too big");
    }
    return size;
}

size_t allocatorL_check_size2(lua_State *L, size_t n, size_t size)
{
    if (n == 0 || size == 0) return 0;
    if ((n * size) > UINTPTR_MAX || size > (_LIBALLOCATOR_SIZE_MAX - _LIBALLOCATOR_HEADER_SIZE) / n)
    {
        luaL_error(L, "memory allocation error: block too big");
    }
    return n * size;
}

static void *block_unwrap(void *block, size_t *size, int *on_heap)
{
    assert(block != NULL);
    void **p = (void **)block - 1;
    *on_heap = (int)((uintptr_t)*p & 1);
    *size = (size_t)((uintptr_t)*p >> 1);
    return (void *)p;
}

static void *block_wrap(void *block, size_t size, int on_heap)
{
    void **p = (void **)block;
    *p = (void *)(uintptr_t)((size << 1) | (size_t)on_heap);
    return (void *)(p + 1);
}

static void *do_realloc0(lua_State *L, void *block, size_t old_size, size_t new_size)
{
    assert(new_size > 0);

    void *ud;
    lua_Alloc alloc = lua_getallocf(L, &ud);
    block = alloc(ud, block, old_size, new_size);
    if (block == NULL)
    {
        lua_gc(L, LUA_GCCOLLECT, 0);
        block = alloc(ud, block, old_size, new_size);
        if (block == NULL)
        {
            luaL_error(L, "memory allocation error: not enough memory");
        }
    }
    return block;
}

static void do_free(lua_State *L, void *block, size_t size)
{
    void *ud;
    lua_Alloc alloc = lua_getallocf(L, &ud);
    alloc(ud, block, size, 0);
}

static void *do_malloc(lua_State *L, size_t size)
{
    void *block = do_realloc0(L, NULL, LUA_TNONE, size);
    return block_wrap(block, size, 1);
}

static void *do_realloc(lua_State *L, void *block, size_t size)
{
    if (block == NULL)
    {
        return do_malloc(L, size);
    }

    int on_heap;
    size_t old_size;
    block = block_unwrap(block, &old_size, &on_heap);

    void *new_block;
    if (on_heap)
    {
        new_block = do_realloc0(L, block, old_size, size);
    }
    else
    {
        new_block = do_realloc0(L, NULL, LUA_TNONE, size);
#if defined(_STD_WINDOWS)
        memcpy_s(new_block, size, block, old_size < size ? old_size : size);
#else
        memcpy(new_block, block, old_size < size ? old_size : size);
#endif
        do_free(L, block, old_size);
    }

    return block_wrap(new_block, size, 1);
}

void *allocatorL_init(lua_State *L, void *block, size_t size)
{
    int on_heap = block == NULL;
    return on_heap ? do_malloc(L, size) : block_wrap(block, size, on_heap);
}

void *allocatorL_realloc(lua_State *L, void *block, size_t size)
{
    size = allocatorL_check_size(L, size);
    if (size == 0)
    {
        allocatorL_free(L, block);
        return NULL;
    }
    return do_realloc(L, block, size + _LIBALLOCATOR_HEADER_SIZE);
}

void *allocatorL_malloc(lua_State *L, size_t size)
{
    size = allocatorL_check_size(L, size);
    return size > 0 ? do_malloc(L, size + _LIBALLOCATOR_HEADER_SIZE) : NULL;
}

void allocatorL_free(lua_State *L, void *block)
{
    if (block == NULL) return;

    int on_heap;
    size_t size;
    block = block_unwrap(block, &size, &on_heap);
    if (on_heap) do_free(L, block, size);
}

size_t allocatorL_size(void *block)
{
    if (block == NULL) return 0;
    void **p = (void **)block - 1;
    return (size_t)((uintptr_t)*p >> 1);
}
