#pragma once
#include <cstdint>

// BBF struct
struct BlockBloomFilter {
    uint64_t* d_bits;
    uint32_t num_words;
    uint32_t num_blocks; // BLOCK_SIZE = m (bit_array size) / b (num_blocks)
    uint32_t k_hashes;
    uint32_t shift;
};