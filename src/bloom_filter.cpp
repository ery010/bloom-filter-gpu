#include <cstddef>
#include <cstdint>
#include <iostream>
#include <string_view>
#include <vector>
#include <utility>

class BloomFilter {
    public:
        BloomFilter(std::size_t bit_count, std::size_t hash_count)
            : bit_count_(bit_count),
              hash_count_(hash_count),
              bits_((bit_count + 63) / 64, 0) {} // Initialize 64-bit words with 0

    
    private:
        std::size_t bit_count_; // declare variable bit_count_ of type std::size_t
        std::size_t hash_count_;
        std::vector<std::uint64_t> bits_;

    

};

int main() {
    return 0;
};