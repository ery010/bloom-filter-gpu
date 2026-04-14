#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstddef>
#include <iostream>
#include <unordered_set>
#include "bloom_filter.h"

void test_no_false_negatives() {
    BloomFilter bf(1 << 16, 3);
    for (std::size_t i = 0; i < 1000; ++i)
        bf.add(i);
    for (std::size_t i = 0; i < 1000; ++i)
        assert(bf.contains(i) && "false negative detected — should be impossible");
    std::cout << "PASS: no false negatives\n";
}

void test_empty_filter_returns_false() {
    BloomFilter bf(1 << 16, 3);
    for (std::size_t i = 0; i < 100; ++i)
        assert(!bf.contains(i) && "empty filter should return false for everything");
    std::cout << "PASS: empty filter returns false\n";
}

void test_single_element() {
    BloomFilter bf(1 << 16, 3);
    bf.add(42);
    assert(bf.contains(42) && "inserted element must be found");
    // These might be false positives but overwhelmingly should be false
    // — we're just checking the happy path here
    std::cout << "PASS: single element found after insert\n";
}

void test_fp_rate_within_tolerance() {
    // m=65536 bits, k=3, n=1000 elements → predicted FP ~= 1.5%
    const std::size_t m = 1 << 16;
    const std::size_t k = 3;
    const std::size_t n = 1000;
    const std::size_t trials = 100000;

    BloomFilter bf(m, k);
    for (std::size_t i = 0; i < n; ++i)
        bf.add(i);

    std::size_t fp = 0;
    for (std::size_t i = n; i < n + trials; ++i)
        if (bf.contains(i)) ++fp;

    double measured  = static_cast<double>(fp) / trials;
    double predicted = bf.fp_rate(n);
    double tolerance = 0.01; // allow 1% deviation from theory

    std::cout << "  predicted: " << predicted
              << "  measured: " << measured << "\n";

    assert(std::abs(measured - predicted) < tolerance
           && "measured FP rate too far from theoretical prediction");
    std::cout << "PASS: FP rate within tolerance\n";
}

void test_no_false_negatives_large() {
    // Stress test: more elements, bigger filter
    BloomFilter bf(1 << 20, 5);
    const std::size_t n = 50000;
    for (std::size_t i = 0; i < n; ++i)
        bf.add(i * 7919); // use a prime stride to vary the keys
    for (std::size_t i = 0; i < n; ++i)
        assert(bf.contains(i * 7919) && "large filter false negative");
    std::cout << "PASS: no false negatives (large filter)\n";
}

void test_different_hash_counts() {
    // k=1 and k=7 are edge cases — make sure the loop logic holds
    for (std::size_t k : {1, 7}) {
        BloomFilter bf(1 << 16, k);
        for (std::size_t i = 0; i < 500; ++i)
            bf.add(i);
        for (std::size_t i = 0; i < 500; ++i)
            assert(bf.contains(i));
    }
    std::cout << "PASS: k=1 and k=7 hash counts work correctly\n";
}

int main() {
    test_empty_filter_returns_false();
    test_single_element();
    test_no_false_negatives();
    test_no_false_negatives_large();
    test_different_hash_counts();
    test_fp_rate_within_tolerance(); // run last — it prints extra info
    std::cout << "\nAll tests passed.\n";
    return 0;
}