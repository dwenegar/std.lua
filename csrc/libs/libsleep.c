#include "std.h"
#if defined(_STD_WINDOWS)
#include "libsleep_win.c"
#else
#include "libsleep_unix.c"
#endif
