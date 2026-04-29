#pragma once
#include <cstdint>
#include <cstddef>
#include <vector>
#include "bloom_common.h"

class BloomFilter {
public:
    BloomFilter(std::size_t bit_count, std::size_t hash_count);
    void add(std::uint64_t key);
    bool contains(std::uint64_t key) const;
    double fp_rate(std::size_t n_elements) const;

private:
    std::size_t bit_count_;
    std::size_t hash_count_;
    std::vector<std::uint64_t> bits_;
    std::pair<std::size_t, std::size_t> hash_pair(std::uint64_t key) const;
};