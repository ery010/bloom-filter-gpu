#include "bloom_filter.h"
#include <cmath>
#include <stdexcept>
#include <bit>

BloomFilter::BloomFilter(std::size_t bit_count, std::size_t hash_count)
{     
    if (bit_count == 0)
        throw std::invalid_argument("bit_count must be greater than 0");
    if (hash_count == 0)
        throw std::invalid_argument("hash_count must be greater than 0");
      
      bit_count_ = bit_count;
      hash_count_ = hash_count;
      bits_.assign((bit_count + 63) / 64, 0);
}

void BloomFilter::add(std::uint64_t key) {
    auto [h1, h2] = hash_pair(key);
    for (std::size_t i = 0; i < hash_count_; ++i) {
        std::size_t bit = (h1 + i * h2) % bit_count_;
        bloom::set_bit(bits_.data(), bit);
    }
}

bool BloomFilter::contains(std::uint64_t key) const {
    auto [h1, h2] = hash_pair(key);
    for (std::size_t i = 0; i < hash_count_; ++i) {
        std::size_t bit = (h1 + i * h2) % bit_count_;
        if (!bloom::check_bit(bits_.data(), bit))
            return false;
    }
    return true;
}

double BloomFilter::fp_rate(std::size_t n_elements) const {
    double exponent = -1.0 * hash_count_ * n_elements / bit_count_;
    return std::pow(1.0 - std::exp(exponent), hash_count_);
}

std::pair<std::size_t, std::size_t> BloomFilter::hash_pair(std::uint64_t key) const {
    std::size_t shift = 64 - (std::bit_width(bit_count_) - 1);
    return {bloom::hash1(key, shift), bloom::hash2(key, shift)};
}