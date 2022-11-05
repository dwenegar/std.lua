#pragma once

#include <stdint.h>

#if defined(_MSC_VER)
#define WIN32_LEAN_AND_MEAN
#elif defined(__GNUC__) || defined(__clang__)
#define _GNU_SOURCE
#endif

#if defined(_MSC_VER)
#define _STD_EXTERN __declspec(dllexport)
#define _STD_ALIGN(x) __declspec(align(x))
#else
#define _STD_EXTERN extern
#define _STD_ALIGN(x) alignas(x)
#endif

#if defined(__GNUC__) || defined(__clang__)
#define _STD_PRIVATE __attribute__((unused)) static
#else
#define _STD_PRIVATE static
#endif

#if defined(_MSC_VER)
#define _STD_NORETURN __declspec(noreturn)
#define _STD_NORETURN_PTR
#elif defined(__GNUC__) || defined(__clang__)
#define _STD_NORETURN __attribute__((__noreturn__))
#define _STD_NORETURN_PTR __attribute__((__noreturn__))
#else
#define _STD_NORETURN
#define _STD_NORETURN_PTR
#endif

#if defined(__APPLE__) && defined(__MACH__)
#define _STD_UNIX
#define _STD_APPLE
#define _STD_MACOS
#define _STD_OS_NAME "macOS"
#elif defined(WIN64) || defined(_WIN64) || defined(__WIN64__)
#define _STD_WINDOWS
#define _STD_WIN64
#define _STD_OS_NAME "Windows"
#elif defined(_WIN32) || defined(_WIN32) || defined(__WIN32__)
#define _STD_WINDOWS
#define _STD_WIN32
#define _STD_OS_NAME "Windows"
#elif defined(linux) || defined(__linux) || defined(__linux__) || defined(__gnu_linux__)
#define _STD_UNIX
#define _STD_LINUX
#define _STD_OS_NAME "Linux"
#else
#error "unsupported OS"
#endif

#if defined(__i386) || defined(__i386__) || defined(_M_IX86)
#define _STD_CPU_32
#define _STD_CPU_X86
#define _STD_CPU_X86_32
#define _STD_CPU_ARCH "x86"
#elif defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64)
#define _STD_CPU_64
#define _STD_CPU_X86
#define _STD_CPU_X86_64
#define _STD_CPU_ARCH "x86_64"
#elif defined(__aarch64__) || defined(_M_ARM64)
#define _STD_CPU_64
#define _STD_CPU_ARM
#define _STD_CPU_ARM64
#define _STD_CPU_ARCH "arm64"
#elif defined(__arm__) || defined(_M_ARM)
#define _STD_CPU_32
#define _STD_CPU_ARM
#define _STD_CPU_ARCH "arm"
#else
#error "Unsupported processor"
#endif

// Endianness
#if defined(_STD_LINUX)
#include <endian.h>
#elif defined(_STD_DARWIN)
#include <machine/endian.h>
#elif defined(_STD_BSD)
#include <sys/endian.h>
#endif

#if defined(__ORDER_BIG_ENDIAN__)
#define _STD_ORDER_BIG_ENDIAN __ORDER_BIG_ENDIAN__
#else
#define _STD_ORDER_BIG_ENDIAN 4321
#endif

#if defined(__ORDER_LITTLE_ENDIAN__)
#define _STD_ORDER_LITTLE_ENDIAN __ORDER_LITTLE_ENDIAN__
#else
#define _STD_ORDER_LITTLE_ENDIAN 1234
#endif

#if defined(__BYTE_ORDER)
#if __BYTE_ORDER == __BIG_ENDIAN
#define _STD_BYTE_ORDER _STD_ORDER_BIG_ENDIAN
#elif __BYTE_ORDER == __LITTLE_ENDIAN
#define _STD_BYTE_ORDER _STD_ORDER_LITTLE_ENDIAN
#else
#error "unsupported byte-order"
#endif
#elif defined(_STD_CPU_X86)
#define _STD_BYTE_ORDER _STD_ORDER_LITTLE_ENDIAN
#else
#error "unsupported byte-order"
#endif

#if defined(_STD_WINDOWS)
#define _STD_PATH_DIRSEP '\\'
#define _STD_PATH_ALTDIRSEP '/'
#define _STD_PATH_PATHSEP ';'
#else
#define _STD_PATH_DIRSEP '/'
#define _STD_PATH_ALTDIRSEP '/'
#define _STD_PATH_PATHSEP ':'
#endif

#if defined(_STD_WINDOWS)
#define _STD_PLATFORM "windows"
#elif defined(_STD_APPLE)
#define _STD_PLATFORM "darwin"
#else
#define _STD_PLATFORM "linux"
#endif

#if !defined(_STD_WINDOWS)
#define sprintf_s snprintf
#elif defined(_WIN64)
typedef signed __int64 ssize_t;
#else
typedef signed int size_t;
#endif
