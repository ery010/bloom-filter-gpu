#pragma once
#include <cuda.h>
#include <cuda_runtime.h>
#include <cstdint>
#include "hash_function.cuh"

// Allocate memory from host
uint32_t* cbf_create(uint64_t m_bits) {
    uint32_t* d_bits;
    cudaMalloc(&d_bits, m_bits / 8);
    cudaMemset(d_bits, 0, m_bits / 8);
    return d_bits;
}



// Free up memory
void cbf_destroy(uint32_t* d_bits) {
    cudaFree(d_bits);
}