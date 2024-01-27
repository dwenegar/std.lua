#include "std.h"

#if defined(_STD_WINDOWS)
#include "libfs_win.c"
#include "libfs_meta_win.c"
#include "libfs_entries_win.c"
#else
#include "libfs_unix.c"
#include "libfs_meta_unix.c"
#include "libfs_entries_unix.c"
#endif
