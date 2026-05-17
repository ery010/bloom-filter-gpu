#include "utils/hash_function.cuh"
#include <cstdio>
#include <cstdint>

// Constants
static constexpr uint32_t k = 7;
static constexpr uint32_t num_blocks = 1024;
static constexpr uint32_t words_per_group = 4;
static constexpr uint32_t block_shift = 64 - 10;
static constexpr uint32_t word_shift = 64 - 2;


// Host
struct HashResult {
    uint64_t seed;
    uint64_t mixed[k];
    uint32_t masks[k];
    uint32_t blk_idx;
    uint32_t word_idx;
};

// Device
__global__ void test_kernel(uint64_t* keys, HashResult* results, int n) {
    uint32_t tid = threadIdx.x;
    if (tid >= n) {
        return;
    }

    uint64_t key = keys[tid];
    uint64_t seed = generate_seed(key);

    results[tid].seed = seed;

    for (uint32_t i = 0; i < k; i++) {
        uint64_t mixed = hash_position(seed, i);
        results[tid].mixed[i] = mixed;
        results[tid].masks[i] = bit_mask(mixed);
    }

    results[tid].blk_idx = block_index(seed, block_shift);
    results[tid].word_idx = word_index(hash_position(seed, 0), word_shift, words_per_group);
}

int main() {

    printf("Hash function test\n");
    
    uint64_t keys[] = {
        1ULL,
        42ULL,
        12345ULL,
        0xDEADBEEFULL,
        0xFFFFFFFFFFFFFFFFULL
    };
    int n = 5;

     // allocate device memory
    uint64_t*   d_keys;
    HashResult* d_results;
    cudaMalloc(&d_keys,    n * sizeof(uint64_t));
    cudaMalloc(&d_results, n * sizeof(HashResult));

    // copy keys to device
    cudaMemcpy(d_keys, keys, n * sizeof(uint64_t), cudaMemcpyHostToDevice);

    // launch kernel
    test_kernel<<<1, n>>>(d_keys, d_results, n);
    cudaDeviceSynchronize();

    // copy results back
    HashResult results[5];
    cudaMemcpy(results, d_results, n * sizeof(HashResult), cudaMemcpyDeviceToHost);

    // checks
    for (int i = 0; i < n; i++) {
        printf("--- key = %lu ---\n", keys[i]);
        printf("seed = %lu\n", results[i].seed);

        for (uint32_t j = 0; j < k; j++) {
            uint32_t mask = results[i].masks[j];
            if (mask != 0 && (mask & (mask - 1)) == 0)
                printf("PASS mask[%u] has one bit set\n", j);
            else
                printf("FAIL mask[%u] has multiple or zero bits\n", j);
        }

        if (results[i].blk_idx < num_blocks)
            printf("PASS block_index in range\n");
        else
            printf("FAIL block_index out of range\n");

        // add word_idx check:
        if (results[i].word_idx < words_per_group)
            printf("PASS word_index in range\n");
        else
            printf("FAIL word_index out of range\n");
            
            printf("\n");
    }

    // free
    cudaFree(d_keys);
    cudaFree(d_results);

    
    return 0;
}