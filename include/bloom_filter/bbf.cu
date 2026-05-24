#include "bbf.cuh"
#include "utils/hash_function.cuh"
#include <cuda_runtime.h>

// Device Kernels

// Insert Kernel
__global__ void bbf_insert_kernel(uint64_t* __restrict__ d_bits, const uint64_t* __restrict__ d_keys, uint64_t n, uint32_t k, uint32_t num_blocks, uint32_t words_per_block, uint32_t shift) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) {
        return;
    };    
}






// Lookup Kernel


// Host wrappers

// Create bloom filter
BlockedBloomFilter create_filter(uint64_t total_bits, uint32_t k, uint32_t num_blocks) {
    // Round up to power of 2; can use std::bit_ceil() in C++20
    
    uint64_t rounded_bits = total_bits;
    if (rounded_bits > 0 && (rounded_bits & (rounded_bits - 1)) != 0) {
        rounded_bits--;
        rounded_bits |= rounded_bits >> 1;
        rounded_bits |= rounded_bits >> 2;
        rounded_bits |= rounded_bits >> 4;
        rounded_bits |= rounded_bits >> 8;
        rounded_bits |= rounded_bits >> 16;
        rounded_bits |= rounded_bits >> 32;
        rounded_bits++;
    }

    BlockedBloomFilter filter;
    filter.num_words = rounded_bits / 64;
    filter.num_blocks = num_blocks;
    filter.words_per_block = filter.num_words / num_blocks;
    filter.k_hashes = k;
    filter.shift = 64 - __builtin_ctz(filter.words_per_block);

    size_t total_bytes = filter.num_words * sizeof(uint64_t);
    cudaMalloc(&filter.d_bits, total_bytes);
    cudaMemset(filter.d_bits, 0, total_bytes);

    return filter;
}

// Insert host wrapper
void bbf_insert(BlockedBloomFilter& filter, const uint64_t* d_keys, uint64_t n) {

}

// Lookup host wrapper
void bbf_lookup() {}


// Free up memory
void bbf_destroy(BlockedBloomFilter& filter) {
    cudaFree(filter.d_bits);
}
