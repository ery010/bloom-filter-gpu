#pragma once
#include <cstdint>
#include <cstddef>

namespace bloom {

// Hash constants — large odd numbers for multiply-shift hashing
static constexpr std::uint64_t A1 = 0x517cc1b727220a95ULL;
static constexpr std::uint64_t A2 = 0x6c62272e07bb0143ULL;

// Set a bit at position `bit` in a uint64_t word array
inline void set_bit(std::uint64_t* words, std::size_t bit) {
    words[bit / 64] |= (1ULL << (bit % 64));
}

// Check if a bit at position `bit` is set in a uint64_t word array
inline bool check_bit(const std::uint64_t* words, std::size_t bit) {
    return words[bit / 64] & (1ULL << (bit % 64));
}

// Multiply-shift hash using constant A1
inline std::uint64_t hash1(std::uint64_t key, std::size_t shift) {
    return (A1 * key) >> shift;
}

// Multiply-shift hash using constant A2
inline std::uint64_t hash2(std::uint64_t key, std::size_t shift) {
    return (A2 * key) >> shift;
}

} // namespace bloom