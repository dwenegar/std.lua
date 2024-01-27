#include "std.h"

#if defined(_STD_WINDOWS)
#include "libenv_win.c"
#else
#include "libenv_unix.c"
#endif
