#pragma once

// xxHash header
#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#define XXH_NO_STREAM
#define XXH_CPU_LITTLE_ENDIAN 1
#include "xxhash.h"

// Other headers
#include <cuda.h>
#include <cuda_runtime.h>
#include <iostream>
#include <cmath>

// Salts
static constexpr uint64_t SALT_0 = 0xBF58476D1CE4E5B9ULL;
static constexpr uint64_t SALT_1 = 0x94D049BB133111EBULL;

// Functions
__device__ __forceinline__ uint64_t generate_seed(uint64_t key) {
    return XXH64(&key, sizeof(uint64_t), 0);
}

__device__ __forceinline__ void hash_pair(uint64_t seed, uint64_t& h0, uint64_t& h1) {
    h0 = seed * SALT_0;
    h1 = (seed * SALT_1 | 1ULL);
}

__device__ __forceinline__ uint64_t hash_mix(uint64_t h0, uint64_t h1, uint32_t i) {
    return h0 + (static_cast<uint64_t>(i) * h1);
}

__device__ __forceinline__ uint32_t block_index(uint64_t h0, uint32_t shift) {
    return static_cast<uint32_t>(h0 >> shift);
}

__device__ __forceinline__ uint32_t word_index(uint64_t mixed, uint32_t shift, uint32_t words_per_group) {
    return static_cast<uint32_t>(mixed >> shift) % words_per_group;
}