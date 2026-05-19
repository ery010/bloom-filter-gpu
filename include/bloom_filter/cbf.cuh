#pragma once
#include <cuda.h>
#include <cuda_runtime.h>
#include <cstdint>
#include "hash_function.cuh"

// Allocate memory from host
uint64_t* cbf_create(uint64_t m_bits) {
    uint64_t* d_bits;
    cudaMalloc(&d_bits, m_bits / 8);
    cudaMemset(d_bits, 0, m_bits / 8);
    return d_bits;
}

// Free up memory
void cbf_destroy(uint64_t* d_bits) {
    cudaFree(d_bits);
}

// Insert
void cbf_insert(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, uint32_t k, uint32_t shift) {

}

// Lookup
void cbf_lookup(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, bool* d_results, uint32_t k, uint32_t shift) {

}