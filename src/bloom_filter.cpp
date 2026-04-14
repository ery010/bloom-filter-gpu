#include "bloom_filter.h"
#include <cmath>

BloomFilter::BloomFilter(std::size_t bit_count, std::size_t hash_count)
    : bit_count_(bit_count),
      hash_count_(hash_count),
      bits_((bit_count + 63) / 64, 0) {}

void BloomFilter::add(std::uint64_t key) {
    auto [h1, h2] = hash_pair(key);
    for (std::size_t i = 0; i < hash_count_; ++i) {
        std::size_t bit = (h1 + i * h2) % bit_count_;
        bits_[bit / 64] |= (1ULL << (bit % 64));
    }
}

bool BloomFilter::contains(std::uint64_t key) const {
    auto [h1, h2] = hash_pair(key);
    for (std::size_t i = 0; i < hash_count_; ++i) {
        std::size_t bit = (h1 + i * h2) % bit_count_;
        if (!(bits_[bit / 64] & (1ULL << (bit % 64))))
            return false;
    }
    return true;
}

double BloomFilter::fp_rate(std::size_t n_elements) const {
    double exponent = -1.0 * hash_count_ * n_elements / bit_count_;
    return std::pow(1.0 - std::exp(exponent), hash_count_);
}

std::pair<std::size_t, std::size_t> BloomFilter::hash_pair(std::uint64_t key) const {
    std::size_t h1 = std::hash<std::uint64_t>{}(key);
    std::size_t h2 = std::hash<std::uint64_t>{}(key ^ 0xdeadbeefcafe1234ULL);
    return {h1, h2};
}