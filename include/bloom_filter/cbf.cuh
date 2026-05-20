#pragma once
#include <cuda.h>
#include <cuda_runtime.h>
#include <cstdint>
#include "hash_function.cuh"

// CBF struct helper
struct ClassicalBloomFilter {
    uint64_t* d_bits;
    uint32_t num_words;
    uint32_t k_hashes;

};

ClassicalBloomFilter create_filter(uint32_t total_bits, uint32_t k);

// Insert
void cbf_insert(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n);

// Lookup
void cbf_lookup(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results);

// Free up memory
void cbf_destroy(ClassicalBloomFilter& filter);