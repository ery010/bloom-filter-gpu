#include "cbf.cuh"
#include "hash_function.cuh"

// Device Kernels

__global__ void cbf_insert_kernel(uint64_t* d_bits, const uint64_t* d_keys, uint64_t n, uint32_t k, uint32_t num_words) {
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) {
        return;
    };

    uint64_t key = d_keys[tid];
}

// Host Wrappers

ClassicalBloomFilter create_filter(uint32_t total_bits, uint32_t k) {
    ClassicalBloomFilter filter;

    filter.num_words = (total_bits + 63) / 64;
    filter.k_hashes = k;

    size_t total_bytes = filter.num_words * sizeof(uint64_t);

}

void cbf_insert(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n) {

}

void cbf_lookup(ClassicalBloomFilter& filter, const uint64_t* d_keys, uint64_t n, bool* d_results) {

}

void cbf_destroy(ClassicalBloomFilter& filter) {

}
