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

// Hash function helpers

// Generate 64-bit seed from raw key via xxHash64
__device__ __forceinline__ uint64_t generate_seed(uint64_t key) {
    return XXH64(&key, sizeof(uint64_t), 0);
}

// Derive base hash values from seed via multiply-shift
__device__ __forceinline__ void hash_pair(uint64_t seed, uint64_t& h0, uint64_t& h1) {
    h0 = seed * SALT_0;
    h1 = (seed * SALT_1 | 1ULL);
}

// Derive ith hash value via double hashing
__device__ __forceinline__ uint64_t hash_mix(uint64_t h0, uint64_t h1, uint32_t i) {
    return h0 + (static_cast<uint64_t>(i) * h1);
}

// Map h0 to block index via top log2(num_blocks) bits
__device__ __forceinline__ uint32_t block_index(uint64_t h0, uint32_t shift) {
    return static_cast<uint32_t>(h0 >> shift);
}

// Map mixed value to word index within a group
__device__ __forceinline__ uint32_t word_index(uint64_t mixed, uint32_t shift, uint32_t words_per_group) {
    return static_cast<uint32_t>(mixed >> shift) % words_per_group;
}

// Map mixed value to single-bit mask within 32-bit word
__device__ __forceinline__ uint32_t bit_mask(uint64_t mixed) {
    return 1u << (mixed & 31);
}