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

    uint64_t key = d_keys[tid];
    uint64_t seed = generate_seed(key);

    uint64_t block_hash = hash_position(seed, 0);
    uint32_t block_id = block_hash % num_blocks;
    uint32_t block_base = block_id * words_per_block;

    for (uint32_t i = 0; i < k; i++) {
        uint64_t mixed = hash_position(seed, i + 1);
        uint64_t word_in_block = (mixed >> shift) % words_per_block;
        uint64_t word = block_base + word_in_block;
        uint64_t mask = 1ULL << (mixed & 0x3F);
        
        atomicOr(reinterpret_cast<unsigned long long*>(d_bits + word), mask);
    }
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
    const uint32_t BLOCK_SIZE = 256;
    uint64_t grid = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;

    bbf_insert_kernel<<<grid, BLOCK_SIZE>>>(filter.d_bits, d_keys, n, filter.k_hashes, filter.num_blocks, filter.words_per_block, filter.shift);

    cudaDeviceSynchronize();
}

// Lookup host wrapper
void bbf_lookup() {}


// Free up memory
void bbf_destroy(BlockedBloomFilter& filter) {
    cudaFree(filter.d_bits);
}
