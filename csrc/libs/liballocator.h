#pragma once

#include "std.h"

#include <lua.h>
#include <limits.h>

#if defined(_STD_WINDOWS)
#include <malloc.h>
#define alloca _alloca
#else
#include <alloca.h>
#endif

#define _LIBALLOCATOR_HEAP_THRESHOLD 1024
#define _LIBALLOCATOR_HEADER_SIZE sizeof(void *)

extern size_t __liballocator_size;

size_t allocatorL_check_size(lua_State *L, size_t size);
size_t allocatorL_check_size2(lua_State *L, size_t n, size_t size);

void *allocatorL_init(lua_State *L, void *block, size_t size);

void *allocatorL_malloc(lua_State *L, size_t size);
#define allocatorL_mallocT(L, T, size) \
    (__liballocator_size = allocatorL_check_size2(L, size, sizeof(T)), allocatorL_malloc(L, __liballocator_size))

void *allocatorL_realloc(lua_State *L, void *block, size_t size);
#define allocatorL_reallocT(L, T, block, size)                         \
    (__liballocator_size = allocatorL_check_size2(L, size, sizeof(T)), \
     allocatorL_realloc(L, block, __liballocator_size))

#define allocatorL_alloc(L, size)                                                      \
    (__liballocator_size = allocatorL_check_size(L, size) + _LIBALLOCATOR_HEADER_SIZE, \
     __liballocator_size < _LIBALLOCATOR_HEAP_THRESHOLD                                \
         ? allocatorL_init(L, alloca(__liballocator_size), __liballocator_size)        \
         : allocatorL_init(L, NULL, __liballocator_size))

#define allocatorL_allocT(L, T, size)                                                              \
    (__liballocator_size = allocatorL_check_size2(L, size, sizeof(T)) + _LIBALLOCATOR_HEADER_SIZE, \
     __liballocator_size < _LIBALLOCATOR_HEAP_THRESHOLD                                            \
         ? allocatorL_init(L, alloca(__liballocator_size), __liballocator_size)                    \
         : allocatorL_init(L, NULL, __liballocator_size))

void allocatorL_free(lua_State *L, void *block);
size_t allocatorL_size(void *block);
