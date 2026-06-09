#include "bloom_filter/cbf.cuh"
#include <stdio.h>

int main () {
    // Initialize keys
    constexpr uint64_t m_bits = 1ULL << 33;   // 1 GB
    constexpr uint32_t k = 16;
    constexpr uint64_t n = 1000000; // 10^6

    // Create keys on host
    uint64_t* h_keys = new uint64_t[n];
    for (uint64_t i = 0; i < n; i++) {
        h_keys[i] = i;
    }

    // Copy to device
    uint64_t* d_keys;
    cudaMalloc(&d_keys, n * sizeof(uint64_t));
    cudaMemcpy(d_keys, h_keys, n * sizeof(uint64_t), cudaMemcpyHostToDevice);

    // Initialized CBF
    ClassicalBloomFilter filter = create_filter(m_bits, k);

    // Insert keys
    printf("Inserting %lu keys...\n", n);
    cbf_insert(filter, d_keys, n);
    cudaDeviceSynchronize();

    // Check for errors
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(err));
        return 1;
    }
    
    printf("Success! Inserted %lu keys\n", n);
    
    // Cleanup
    cudaFree(d_keys);
    cudaFree(filter.d_bits);
    delete[] h_keys;
    
    return 0;
}