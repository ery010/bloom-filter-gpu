#include "cbf.cuh"
#include "utils/hash_function.cuh"
#include <cuda_runtime.h>

// Device Kernels

// Insert Kernel
__global__ void cbf_insert_kernel(uint64_t* __restrict__ d_bits, const uint64_t* __restrict__ d_keys, uint64_t n, uint32_t k, uint32_t num_words, uint32_t shift) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) {
        return;
    };

    uint64_t key = d_keys[tid];
    uint64_t seed = generate_seed(key);

    for (uint32_t i = 0; i < k; i++) {
        uint64_t mixed = hash_position(seed, i);
        uint64_t word = (mixed >> shift) % num_words;
        uint64_t mask = bit_mask(mixed);

        atomicOr(reinterpret_cast<unsigned long long*>(d_bits + word), mask);
    }
}

// Lookup Kernel
__global__ void cbf_lookup_kernel(const uint64_t* __restrict__ d_bits, const uint64_t* __restrict__ d_keys, uint64_t n, bool* __restrict__ d_results, uint32_t k, uint32_t num_words, uint32_t shift) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) {
        return;
    };

    uint64_t key = d_keys[tid];
    uint64_t seed = generate_seed(key);

    bool found = true;

    for (uint32_t i = 0; i < k; i++) {
        uint64_t mixed = hash_position(seed, i);
        uint64_t word = (mixed >> shift) % num_words;
        uint64_t mask = bit_mask(mixed);

        if ((d_bits[word] & mask) == 0) {
            found = false;
            break;
        }
    }
    d_results[tid] = found;
}

// Host Wrappers

// Create the bloom filter
ClassicalBloomFilter create_filter(uint64_t total_bits, uint32_t k) {

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

    ClassicalBloomFilter filter;
    filter.num_words = rounded_bits / 64;
    filter.k_hashes = k;
    filter.shift = 64 - __builtin_ctz(filter.num_words); // log2(num_words), powers of 2 always have trailing zeros

    size_t total_bytes = filter.num_words * sizeof(uint64_t);
    cudaMalloc(&filter.d_bits, total_bytes);
    cudaMemset(filter.d_bits, 0, total_bytes);

    return filter;
}

// Insert host wrapper
void cbf_insert(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n) {
    constexpr uint32_t BLOCK_SIZE = 256;
    uint64_t grid = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;

    cbf_insert_kernel<<<grid, BLOCK_SIZE>>>(filter.d_bits, d_keys, n, filter.k_hashes, filter.num_words, filter.shift);

    cudaDeviceSynchronize();
}

// Lookup host wrapper
void cbf_lookup(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results) {
    constexpr uint32_t BLOCK_SIZE = 256;
    uint64_t grid = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;

    cbf_lookup_kernel<<<grid, BLOCK_SIZE>>>(filter.d_bits, d_keys, n, d_results, filter.k_hashes, filter.num_words, filter.shift);
    
    cudaDeviceSynchronize();
}

// Free up memory
void cbf_destroy(ClassicalBloomFilter& filter) {
    cudaFree(filter.d_bits);
}
