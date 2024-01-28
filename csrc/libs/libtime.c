#include "std.h"
#if defined(_STD_WINDOWS)
#include "libtime_win.c"
#else
#include "libtime_unix.c"
#endif
