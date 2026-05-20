#include "cbf.cuh"
#include "hash_function.cuh"

// Device Kernels

__global__ void cbf_insert_kernel(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, uint32_t k, uint32_t num_words) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    uint64_t key = d_keys[tid];
}