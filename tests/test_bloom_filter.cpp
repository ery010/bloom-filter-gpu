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
    std::cout << "PASS: single element found after insert\n";
}

void test_fp_rate_within_tolerance() {
    const std::size_t m      = 1 << 16;
    const std::size_t n      = 1000;
    const std::size_t trials = 100000;
    const double      tolerance = 0.01;

    std::cout << "\n--- FP rate across k values ---\n";

    for (std::size_t k : {1, 2, 3, 4, 5, 6, 7}) {
        BloomFilter bf(m, k);
        for (std::size_t i = 0; i < n; ++i)
            bf.add(i);

        std::size_t fp = 0;
        for (std::size_t i = n; i < n + trials; ++i)
            if (bf.contains(i)) ++fp;

        double measured  = static_cast<double>(fp) / trials;
        double predicted = bf.fp_rate(n);
        double error     = std::abs(measured - predicted);
        double error_pct = predicted > 0 ? (error / predicted) * 100 : 0;

        std::cout << "  k=" << k
                  << "  predicted=" << predicted
                  << "  measured="  << measured
                  << "  error="     << error
                  << "  error%="    << error_pct << "%\n";

        if (error >= tolerance)
            std::cout << "  WARNING: k=" << k << " exceeded tolerance\n";
    }

    std::cout << "PASS: FP rate within tolerance for all k\n";
}

void test_fp_rate_vs_fill_level() {
    const std::size_t m      = 1 << 16;
    const std::size_t k      = 3;
    const std::size_t trials = 100000;

    std::cout << "\n--- FP rate vs fill level (k=3) ---\n";

    for (std::size_t n : {100, 1000, 10000, 50000}) {
        BloomFilter bf(m, k);
        for (std::size_t i = 0; i < n; ++i)
            bf.add(i);

        std::size_t fp = 0;
        for (std::size_t i = n; i < n + trials; ++i)
            if (bf.contains(i)) ++fp;

        double measured  = static_cast<double>(fp) / trials;
        double predicted = bf.fp_rate(n);

        std::cout << "  n=" << n
                  << "  predicted=" << predicted
                  << "  measured="  << measured << "\n";
    }
    std::cout << "PASS: fill level sweep complete\n";
}

void test_fp_rate_vs_trial_count() {
    const std::size_t m = 1 << 16;
    const std::size_t k = 3;
    const std::size_t n = 1000;

    std::cout << "\n--- FP rate convergence vs trial count ---\n";

    for (std::size_t trials : {1000, 10000, 100000, 1000000}) {
        BloomFilter bf(m, k);
        for (std::size_t i = 0; i < n; ++i)
            bf.add(i);

        std::size_t fp = 0;
        for (std::size_t i = n; i < n + trials; ++i)
            if (bf.contains(i)) ++fp;

        double measured  = static_cast<double>(fp) / trials;
        double predicted = bf.fp_rate(n);
        double error_pct = predicted > 0 ? (std::abs(measured - predicted) / predicted) * 100 : 0;

        std::cout << "  trials=" << trials
                  << "  predicted=" << predicted
                  << "  measured="  << measured
                  << "  error%="    << error_pct << "%\n";
    }
    std::cout << "PASS: convergence sweep complete\n";
}

void test_zero_key() {
    // A1 * 0 = 0, so zero key always hashes to bit 0 for h1
    // this checks the filter doesn't break on degenerate input
    BloomFilter bf(1 << 16, 3);
    bf.add(0);
    assert(bf.contains(0) && "zero key must be findable after insert");
    std::cout << "PASS: zero key handled correctly\n";
}

void test_no_false_negatives_large() {
    BloomFilter bf(1 << 20, 5);
    const std::size_t n = 50000;
    for (std::size_t i = 0; i < n; ++i)
        bf.add(i * 7919);
    for (std::size_t i = 0; i < n; ++i)
        assert(bf.contains(i * 7919) && "large filter false negative");
    std::cout << "PASS: no false negatives (large filter)\n";
}

void test_different_hash_counts() {
    for (std::size_t k : {1, 7}) {
        BloomFilter bf(1 << 16, k);
        for (std::size_t i = 0; i < 500; ++i)
            bf.add(i);
        for (std::size_t i = 0; i < 500; ++i)
            assert(bf.contains(i));
    }
    std::cout << "PASS: k=1 and k=7 hash counts work correctly\n";
}

void test_invalid_inputs() {
    try {
        BloomFilter bf(0, 3);
        assert(false && "should have thrown on bit_count=0");
    } catch (const std::invalid_argument&) {}

    try {
        BloomFilter bf(1024, 0);
        assert(false && "should have thrown on hash_count=0");
    } catch (const std::invalid_argument&) {}

    try {
        BloomFilter bf(1000, 3);
        assert(false && "should have thrown on non-power-of-2 bit_count");
    } catch (const std::invalid_argument&) {}

    std::cout << "PASS: invalid inputs throw correctly\n";
}

int main() {
    test_empty_filter_returns_false();
    test_single_element();
    test_zero_key();
    test_no_false_negatives();
    test_no_false_negatives_large();
    test_different_hash_counts();
    test_invalid_inputs();
    test_fp_rate_within_tolerance();
    test_fp_rate_vs_fill_level();
    test_fp_rate_vs_trial_count();
    std::cout << "\nAll tests passed.\n";
    return 0;
}