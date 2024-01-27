#pragma once

#include "std.h"
#include "liballocator.h"

#include <stdint.h>
#include <string.h>
#include <wchar.h>

typedef struct
{
    const char *ptr;
    const size_t info;
} cstr_t;

#define _CSTR_NULL (cstr_t) {0, 0};

#define cstr_literal(s) ((cstr_t) {.ptr = s, .info = (sizeof(s) - 1) << 1})

const cstr_t cstr_alloc(lua_State *L, size_t size);
const cstr_t cstr_refx(const char *ptr, size_t len);
const cstr_t cstr_ref(const char *ptr);
const char *cstr_ptr(const cstr_t s);

void cstr_free(lua_State *L, const cstr_t s);

const size_t cstr_length(const cstr_t s);
const cstr_t cstr_concat(lua_State *L, const cstr_t x, const cstr_t y);
