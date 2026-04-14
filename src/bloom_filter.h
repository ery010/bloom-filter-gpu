#pragma once
#include <cstdint>
#include <cstddef>
#include <vector>

class BloomFilter {
public:
    BloomFilter(std::size_t bit_count, std::size_t hash_count);
    void add(std::uint64_t key);
    bool contains(std::uint64_t key) const;
    double fp_rate(std::size_t n_elements) const;

private:
    static constexpr std::uint64_t A1 = 0x517cc1b727220a95ULL;
    static constexpr std::uint64_t A2 = 0x6c62272e07bb0143ULL;
    
    std::size_t bit_count_;
    std::size_t hash_count_;
    std::size_t log2_bits_;
    std::vector<std::uint64_t> bits_;
    std::pair<std::size_t, std::size_t> hash_pair(std::uint64_t key) const;
};