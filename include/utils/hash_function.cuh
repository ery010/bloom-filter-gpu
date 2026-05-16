#pragma once

#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#define XXH_NO_STREAM
#define XXH_CPU_LITTLE_ENDIAN 1
#include "xxhash.h"

#include <cuda.h>
#include <cuda_runtime.h>