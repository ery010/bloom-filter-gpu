#pragma once
#include <cuda.h>
#include <cuda_runtime.h>
#include <cstdint>

// Salt constants for multiplicative hashing
// All values are large odd 64-bit constants sourced from
// well-known hash functions (splitmix64, MurmurHash3, FNV, xoshiro)
// The paper (Jünger et al. 2025) specifies the mechanism but not
// the exact values — these are our own chosen constants satisfying
// the mathematical requirements.
static constexpr __device__ uint64_t SALTS[] = {
    0x9E3779B185EBCA87ULL,  // Fibonacci hashing / golden ratio
    0xBF58476D1CE4E5B9ULL,  // splitmix64 multiplier 1
    0x94D049BB133111EBULL,  // splitmix64 multiplier 2
    0xC4CEB9FE1A85EC53ULL,  // MurmurHash3 mix constant
    0xFF51AFD7ED558CCDULL,  // MurmurHash3 finalizer 1
    0xE7037ED1A0B428DBULL,  // MurmurHash3 finalizer 2
    0x6B14E4A7A0B91597ULL,  // xoshiro256 constant
    0xB5026F5AA96619E9ULL,  // xoshiro256** multiplier
    0xD2A98B26625EEE7BULL,  // xxHash prime 1
    0x9DDFEA08EB382D69ULL,  // CityHash mix constant
    0x517CC1B727220A95ULL,  // WarpCore hash table constant
    0x6C62272E07BB0143ULL,  // FNV-1a 64-bit prime variant
    0xAB2F9F6B8B4E3C1DULL,  // manually chosen, verified odd
    0xD1B54A32D192ED03ULL,  // manually chosen, verified odd
    0x246C1D2BB1C6E26FULL,  // manually chosen, verified odd
    0xD2B74407B1CE6E93ULL,  // manually chosen, verified odd
};

// Hash function helpers

// Generate 64-bit seed from raw key via xxHash64
__device__ __forceinline__ uint64_t generate_seed(uint64_t key) {
    constexpr uint64_t PRIME1 = 0x9E3779B185EBCA87ULL;
    constexpr uint64_t PRIME2 = 0xC2B2AE3D27D4EB4FULL;
    constexpr uint64_t PRIME3 = 0x165667B19E3779F9ULL;
    constexpr uint64_t PRIME4 = 0x85EBCA77C2B2AE63ULL;
    constexpr uint64_t PRIME5 = 0x27D4EB2F165667C5ULL;

    uint64_t h = PRIME5 + 8;
    h ^= key * PRIME3;
    h = ((h << 31) | (h >> 33)) * PRIME1;
    h ^= h >> 33;
    h *= PRIME2;
    h ^= h >> 29;
    h *= PRIME3;
    h ^= h >> 32;
    return h;
}

// Seed and one salt index
__device__ __forceinline__ uint64_t hash_position(uint64_t seed, uint32_t i) {
    return seed * SALTS[i];
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