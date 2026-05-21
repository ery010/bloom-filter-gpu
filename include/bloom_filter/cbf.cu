#include "cbf.cuh"
#include "hash_function.cuh"
#include <bit>

// Device Kernels

__global__ void cbf_insert_kernel(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, uint32_t k, uint32_t num_words, uint32_t shift) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) {
        return;
    };

    uint64_t key = d_keys[tid];
}

// Host Wrappers

ClassicalBloomFilter create_filter(uint32_t total_bits, uint32_t k) {

    // Round up to power of 2; can use std::bit_ceil() in C++20
    uint32_t rounded_bits = total_bits;
    if (rounded_bits > 0 && (rounded_bits & (rounded_bits - 1)) != 0) {
        rounded_bits--;
        rounded_bits |= rounded_bits >> 1;
        rounded_bits |= rounded_bits >> 2;
        rounded_bits |= rounded_bits >> 4;
        rounded_bits |= rounded_bits >> 8;
        rounded_bits |= rounded_bits >> 16;
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

void cbf_insert(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n) {

}

void cbf_lookup(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results) {

}

void cbf_destroy(ClassicalBloomFilter& filter) {

}
