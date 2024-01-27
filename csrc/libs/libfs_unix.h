#pragma once

#define timespec_to_millis(ts) ((ts).tv_sec * MILLIS_PER_SECOND + (ts).tv_nsec / NANOS_PER_MILLI)
