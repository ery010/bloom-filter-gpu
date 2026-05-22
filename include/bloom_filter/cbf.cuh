#pragma once
#include <cstdint>

// CBF struct
struct ClassicalBloomFilter {
    uint64_t* d_bits;
    uint32_t num_words;
    uint32_t k_hashes;
    uint32_t shift;

};

ClassicalBloomFilter create_filter(uint64_t total_bits, uint32_t k);

// Insert
void cbf_insert(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n);

// Lookup
void cbf_lookup(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results);

// Free up memory
void cbf_destroy(ClassicalBloomFilter& filter);
