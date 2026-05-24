#include "bloom_filter/bbf.cuh"
#include <cuda_runtime.h>
#include <random>
#include <vector>
#include <cstdio>
#include <chrono>
#include <cmath>

int main() {
    // Setup
    uint64_t n = 1000000;
    uint64_t* h_keys = new uint64_t[n];
    for (uint64_t i = 0; i < n; i++) {
        h_keys[i] = i;
    }
    
    uint64_t* d_keys;
    cudaMalloc(&d_keys, n * sizeof(uint64_t));
    cudaMemcpy(d_keys, h_keys, n * sizeof(uint64_t), cudaMemcpyHostToDevice);
    
    // Create filter
    BlockedBloomFilter filter = create_filter(1ULL << 33, 16, 1024);
    
    // Test insertion
    printf("Inserting %lu keys...\n", n);
    bbf_insert(filter, d_keys, n);
    cudaDeviceSynchronize();
    
    // Check GPU errors
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(err));
        return 1;
    }
    
    printf("✓ Insertion successful!\n");
    
    // Cleanup
    cudaFree(d_keys);
    cudaFree(filter.d_bits);
    delete[] h_keys;
    
    return 0;
}