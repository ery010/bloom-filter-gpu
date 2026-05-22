#include "bloom_filter/cbf.cuh"
#include <cuda_runtime.h>
#include <random>
#include <vector>
#include <cstdio>
#include <chrono>
#include <cmath>

int main() {
    constexpr uint64_t m_bits = 1ULL << 33;   // 1 GB
    constexpr uint32_t k = 16;
    constexpr uint64_t n_insert = 1000000000; // 10^9
    constexpr uint64_t n_query = 10000000;    // 10M queries

    printf("=== CBF Performance Test ===\n");
    printf("Filter: %lu bits (%.2f GB)\n", m_bits, m_bits / 8.0 / 1e9);
    printf("Insert: %lu keys\n", n_insert);
    printf("Query:  %lu keys\n\n", n_query);

    auto t0 = std::chrono::high_resolution_clock::now();

    // Create filter
    printf("Creating filter...\n");
    auto filter = create_filter(m_bits, k);
    auto t1 = std::chrono::high_resolution_clock::now();
    printf("  Done: %.2f seconds\n\n", 
           std::chrono::duration<double>(t1-t0).count());

    // Generate insert keys
    printf("Generating %lu insert keys on host...\n", n_insert);
    std::mt19937_64 rng(42);
    std::vector<uint64_t> keys(n_insert);
    for (auto& key : keys) key = rng();
    auto t2 = std::chrono::high_resolution_clock::now();
    printf("  Done: %.2f seconds\n\n", 
           std::chrono::duration<double>(t2-t1).count());

    // Allocate device memory
    printf("Allocating device memory...\n");
    uint64_t* d_keys;
    bool* d_results;
    cudaMalloc(&d_keys, n_insert * sizeof(uint64_t));
    cudaMalloc(&d_results, n_query * sizeof(bool));
    auto t3 = std::chrono::high_resolution_clock::now();
    printf("  Done: %.2f seconds\n\n", 
           std::chrono::duration<double>(t3-t2).count());

    // Copy insert keys to device
    printf("Copying insert keys to device (%.2f GB)...\n", 
           n_insert * sizeof(uint64_t) / 1e9);
    cudaMemcpy(d_keys, keys.data(), 
               n_insert * sizeof(uint64_t), cudaMemcpyHostToDevice);
    auto t4 = std::chrono::high_resolution_clock::now();
    printf("  Done: %.2f seconds\n\n", 
           std::chrono::duration<double>(t4-t3).count());

    // Insert
    printf("Inserting %lu keys...\n", n_insert);
    cbf_insert(filter, d_keys, n_insert);
    auto t5 = std::chrono::high_resolution_clock::now();
    double insert_sec = std::chrono::duration<double>(t5-t4).count();
    printf("  Done: %.2f seconds (%.2f M keys/sec)\n\n", 
           insert_sec, n_insert / insert_sec / 1e6);

    // === Test 1: No false negatives (lookup inserted keys) ===
    printf("Test 1: Checking for false negatives (sample of inserted keys)...\n");
    uint64_t sample_size = std::min(n_query, n_insert);
    cbf_lookup(filter, d_keys, sample_size, d_results);
    
    std::vector<uint8_t> results(sample_size);
    cudaMemcpy(results.data(), d_results, sample_size * sizeof(bool), 
               cudaMemcpyDeviceToHost);
    
    uint64_t false_negatives = 0;
    for (auto found : results) {
        if (!found) false_negatives++;
    }
    
    if (false_negatives == 0) {
        printf("  PASS: No false negatives (0/%lu)\n\n", sample_size);
    } else {
        printf("  FAIL: %lu false negatives out of %lu\n\n", 
               false_negatives, sample_size);
    }

    // === Test 2: Measure FPR with non-inserted keys ===
    printf("Test 2: Measuring false positive rate with new keys...\n");
    
    // Generate new query keys (different from insert)
    printf("  Generating %lu new query keys...\n", n_query);
    for (auto& key : keys) key = rng();  // reuse host buffer, new random keys
    auto t6 = std::chrono::high_resolution_clock::now();
    printf("    Done: %.2f seconds\n", 
           std::chrono::duration<double>(t6-t5).count());
    
    // Copy to device (reuse d_keys buffer)
    printf("  Copying query keys to device...\n");
    cudaMemcpy(d_keys, keys.data(), 
               n_query * sizeof(uint64_t), cudaMemcpyHostToDevice);
    auto t7 = std::chrono::high_resolution_clock::now();
    printf("    Done: %.2f seconds\n", 
           std::chrono::duration<double>(t7-t6).count());
    
    // Lookup
    printf("  Looking up %lu keys...\n", n_query);
    cbf_lookup(filter, d_keys, n_query, d_results);
    auto t8 = std::chrono::high_resolution_clock::now();
    double lookup_sec = std::chrono::duration<double>(t8-t7).count();
    printf("    Done: %.2f seconds (%.2f M keys/sec)\n", 
           lookup_sec, n_query / lookup_sec / 1e6);
    
    // Check results
    results.resize(n_query);
    cudaMemcpy(results.data(), d_results, n_query * sizeof(bool), 
               cudaMemcpyDeviceToHost);
    
    uint64_t false_positives = 0;
    for (auto found : results) {
        if (found) false_positives++;
    }
    
    double measured_fpr = (double)false_positives / n_query;
    double theoretical_fpr = pow(1.0 - exp(-(double)k * n_insert / m_bits), k);
    double ratio = measured_fpr / theoretical_fpr;
    
    printf("\n  Measured FPR:    %.6f (%lu/%lu)\n", measured_fpr, 
           false_positives, n_query);
    printf("  Theoretical FPR: %.6f\n", theoretical_fpr);
    printf("  Ratio:           %.2fx\n", ratio);
    
    if (ratio < 3.0) {
        printf("  PASS: FPR within 3x of theoretical\n\n");
    } else {
        printf("  FAIL: FPR too high (>3x theoretical)\n\n");
    }

    // Cleanup
    cudaFree(d_keys);
    cudaFree(d_results);
    cbf_destroy(filter);

    printf("=== Test Complete ===\n");
    return 0;
}