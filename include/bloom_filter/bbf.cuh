#pragma once
#include <cstdint>

// BBF struct
struct BlockedBloomFilter {
    uint64_t* d_bits;
    uint32_t num_words;
    uint32_t num_blocks; // BLOCK_SIZE = m (bit_array size) / b (num_blocks)
    uint32_t words_per_block;
    uint32_t k_hashes;
    uint32_t shift;
};

BlockedBloomFilter create_filter(uint64_t total_bits, uint32_t k, uint32_t num_blocks);

// Insert
void bbf_insert(BlockedBloomFilter& filter, const uint64_t* d_keys, uint64_t n);

// Lookup
void bbf_lookup(BlockedBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results);

// Free up memory
void bbf_destroy(BlockedBloomFilter& filter);

