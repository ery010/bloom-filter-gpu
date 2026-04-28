#include "blocked_bloom_filter.h"
#include <cmath>
#include <bit>
#include <stdexcept>

BlockedBloomFilter::BlockedBloomFilter(std::size_t bit_count, std::size_t hash_count, std::size_t block_size){
    if (bit_count == 0)
        throw std::invalid_argument("bit_count must be greater than 0");
    if (hash_count == 0)
        throw std::invalid_argument("hash_count must be greater than 0");
    if (block_size == 0)
        throw std::invalid_argument("block_size must be greater than 0");
    if ((bit_count & (bit_count - 1)) != 0)
        throw std::invalid_argument("bit_count must be a power of 2");
    if ((block_size & (block_size - 1)) != 0)
        throw std::invalid_argument("block_size must be a power of 2");
    if (bit_count % block_size != 0)
        throw std::invalid_argument("bit_count must be divisible by block_size");
}