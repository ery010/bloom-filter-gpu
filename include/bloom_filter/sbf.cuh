#pragma once
#include <cstdint>

// SBF struct
struct SectorizedBloomFilter {
    uint64_t* d_bits;
    uint32_t num_words;
    uint32_t num_blocks; // BLOCK_SIZE = m (bit_array size) / b (num_blocks)
    uint32_t sectors_per_block;
    uint32_t words_per_sector;
    uint32_t k_hashes;
    uint32_t shift;

};