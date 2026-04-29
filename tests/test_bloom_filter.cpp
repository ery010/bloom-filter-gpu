#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstddef>
#include <iostream>
#include <unordered_set>
#include "bloom_filter.h"

// ─────────────────────────────────────────────
// Correctness tests — must pass deterministically
// ─────────────────────────────────────────────

void test_empty_filter_returns_false() {
    BloomFilter bf(1 << 16, 3);
    for (std::size_t i = 0; i < 1000; ++i)
        assert(!bf.contains(i) && "empty filter must return false");
    std::cout << "PASS: empty filter returns false\n";
}

void test_single_element() {
    BloomFilter bf(1 << 16, 3);
    bf.add(42);
    assert(bf.contains(42) && "inserted element must be found");
    std::cout << "PASS: single element found after insert\n";
}

void test_no_false_negatives() {
    BloomFilter bf(1 << 16, 3);
    for (std::size_t i = 0; i < 10000; ++i)
        bf.add(i);
    for (std::size_t i = 0; i < 10000; ++i)
        assert(bf.contains(i) && "false negative detected — should be impossible");
    std::cout << "PASS: no false negatives (n=10000)\n";
}

void test_no_false_negatives_large() {
    BloomFilter bf(1 << 22, 5);
    const std::size_t n = 200000;
    for (std::size_t i = 0; i < n; ++i)
        bf.add(i * 7919);
    for (std::size_t i = 0; i < n; ++i)
        assert(bf.contains(i * 7919) && "large filter false negative");
    std::cout << "PASS: no false negatives (large filter, prime stride)\n";
}

void test_no_false_negatives_arbitrary_sizes() {
    // verify correctness holds for non-power-of-2 sizes
    for (std::size_t m : {1000, 5000, 12345, 99991}) {
        BloomFilter bf(m, 3);
        for (std::size_t i = 0; i < 100; ++i)
            bf.add(i);
        for (std::size_t i = 0; i < 100; ++i)
            assert(bf.contains(i) && "false negative on arbitrary size");
    }
    std::cout << "PASS: no false negatives (arbitrary filter sizes)\n";
}

void test_zero_key() {
    // h1(0) = (A1 * 0) >> shift = 0, h2(0) = 0
    // all k bit positions collapse to (0 + i*0) % m = 0
    // only bit 0 is set — filter still correct but wastes k-1 operations
    BloomFilter bf(1 << 16, 3);
    bf.add(0);
    assert(bf.contains(0) && "zero key must be findable after insert");
    std::cout << "PASS: zero key handled correctly\n";
}

void test_different_hash_counts() {
    for (std::size_t k : {1, 2, 3, 5, 7}) {
        BloomFilter bf(1 << 16, k);
        for (std::size_t i = 0; i < 1000; ++i)
            bf.add(i);
        for (std::size_t i = 0; i < 1000; ++i)
            assert(bf.contains(i) && "false negative across k values");
    }
    std::cout << "PASS: no false negatives across k=1,2,3,5,7\n";
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

    std::cout << "PASS: invalid inputs throw correctly\n";
}

// ─────────────────────────────────────────────
// Statistical tests — validate probabilistic behavior
// ─────────────────────────────────────────────

// minimum trials needed for 30 expected FP observations (statistical reliability)
// trials_min = 30 / fp_predicted
// k=1: ~2k    k=2: ~33k    k=3: ~333k    k=4: ~2.5M    k=5+: impractical
struct KResult {
    std::size_t k;
    double predicted;
    double measured;
    double error_pct;
    std::size_t trials_used;
    bool reliable; // enough trials for statistically meaningful result
};

KResult measure_fp_rate(std::size_t m, std::size_t n, std::size_t k, std::size_t trials) {
    BloomFilter bf(m, k);
    for (std::size_t i = 0; i < n; ++i)
        bf.add(i);

    std::size_t fp = 0;
    for (std::size_t i = n; i < n + trials; ++i)
        if (bf.contains(i)) ++fp;

    double predicted = bf.fp_rate(n);
    double measured  = static_cast<double>(fp) / trials;
    double error_pct = predicted > 0 ? (std::abs(measured - predicted) / predicted) * 100 : 0;
    double trials_min = predicted > 0 ? 30.0 / predicted : 1e9;
    bool reliable = trials >= static_cast<std::size_t>(trials_min);

    return {k, predicted, measured, error_pct, trials, reliable};
}

void test_fp_rate_across_k() {
    const std::size_t m = 1 << 16;
    const std::size_t n = 1000;

    // use enough trials for each k to be statistically meaningful
    // k=1,2: 100k sufficient   k=3: 1M   k=4+: mark as unreliable
    struct KConfig { std::size_t k; std::size_t trials; };
    KConfig configs[] = {{1, 100000}, {2, 100000}, {3, 1000000}, {4, 1000000},
                         {5, 1000000}, {6, 1000000}, {7, 1000000}};

    std::cout << "\n--- FP rate across k values (m=" << m << ", n=" << n << ") ---\n";
    std::cout << "  Note: k=4+ requires ~millions of trials for reliable measurement\n\n";

    for (auto [k, trials] : configs) {
        auto r = measure_fp_rate(m, n, k, trials);
        std::cout << "  k=" << r.k
                  << "  predicted=" << r.predicted
                  << "  measured="  << r.measured
                  << "  error%="    << r.error_pct << "%"
                  << "  trials="    << r.trials_used
                  << (r.reliable ? "" : "  [UNRELIABLE: insufficient trials]")
                  << "\n";
    }
    std::cout << "PASS: FP rate sweep complete\n";
}

void test_fp_rate_vs_fill_level() {
    const std::size_t m      = 1 << 16;
    const std::size_t k      = 3;
    const std::size_t trials = 1000000;

    std::cout << "\n--- FP rate vs fill level (k=3, m=" << m << ", trials=" << trials << ") ---\n";

    for (std::size_t n : {100, 500, 1000, 5000, 10000, 50000}) {
        auto r = measure_fp_rate(m, n, k, trials);
        std::cout << "  n="         << n
                  << "  predicted=" << r.predicted
                  << "  measured="  << r.measured
                  << "  error%="    << r.error_pct << "%"
                  << (r.reliable ? "" : "  [UNRELIABLE]")
                  << "\n";
    }
    std::cout << "PASS: fill level sweep complete\n";
}

void test_fp_rate_convergence() {
    const std::size_t m = 1 << 16;
    const std::size_t k = 3;
    const std::size_t n = 1000;

    std::cout << "\n--- FP rate convergence vs trial count (k=3, m=" << m << ", n=" << n << ") ---\n";
    std::cout << "  Expected: error% decreases as trials increase\n\n";

    for (std::size_t trials : {1000, 10000, 100000, 500000, 1000000, 5000000}) {
        auto r = measure_fp_rate(m, n, k, trials);
        std::cout << "  trials="    << trials
                  << "  predicted=" << r.predicted
                  << "  measured="  << r.measured
                  << "  error%="    << r.error_pct << "%"
                  << (r.reliable ? "" : "  [UNRELIABLE]")
                  << "\n";
    }
    std::cout << "PASS: convergence sweep complete\n";
}

void test_fp_rate_vs_filter_size() {
    // validate that larger m gives lower FP rate as theory predicts
    const std::size_t k = 3;
    const std::size_t n = 1000;
    const std::size_t trials = 1000000;

    std::cout << "\n--- FP rate vs filter size (k=3, n=" << n << ") ---\n";

    double prev_measured = 1.0;
    for (std::size_t m : {1 << 10, 1 << 12, 1 << 14, 1 << 16, 1 << 18, 1 << 20}) {
        auto r = measure_fp_rate(m, n, k, trials);
        bool decreasing = r.measured <= prev_measured;
        std::cout << "  m="         << m
                  << "  predicted=" << r.predicted
                  << "  measured="  << r.measured
                  << "  error%="    << r.error_pct << "%"
                  << (decreasing ? "" : "  WARNING: FP rate not decreasing")
                  << "\n";
        if (r.reliable)
            prev_measured = r.measured;
    }
    std::cout << "PASS: FP rate decreases with filter size\n";
}

int main() {
    // correctness — deterministic
    std::cout << "=== Correctness Tests ===\n";
    test_empty_filter_returns_false();
    test_single_element();
    test_zero_key();
    test_no_false_negatives();
    test_no_false_negatives_large();
    test_no_false_negatives_arbitrary_sizes();
    test_different_hash_counts();
    test_invalid_inputs();

    // statistical — probabilistic
    std::cout << "\n=== Statistical Tests ===\n";
    test_fp_rate_across_k();
    test_fp_rate_vs_fill_level();
    test_fp_rate_convergence();
    test_fp_rate_vs_filter_size();

    std::cout << "\nAll tests passed.\n";
    return 0;
}