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

ClassicalBloomFilter create_filter(uint32_t total_bits, uint32_t k) {
    ClassicalBloomFilter filter;

    // Round to nearest 64-bit word
    filter.num_words = (total_bits + 63) / 64;
    filter.k_hashes = k;
    
    // Total bytes to allocate
    size_t total_bytes = filter.num_words * sizeof(uint64_t);

    cudaMalloc((void**)&filter.d_bits, total_bytes);
    cudaMemset(filter.d_bits, 0, total_bytes);

    return filter;

}




// Insert
void cbf_insert(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, uint32_t k, uint32_t shift) {

}

// Lookup
void cbf_lookup(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, bool* d_results, uint32_t k, uint32_t shift) {

}

// Free up memory
void cbf_destroy(uint64_t* d_bits) {
    cudaFree(d_bits);
}