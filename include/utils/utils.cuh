#pragma once

// vec_load_words: Vectorized memory load utility
// Source: Listing 1, Jünger et al. (2025)
// "Optimizing Bloom Filters for Modern GPU Architectures"
// https://arxiv.org/abs/2512.15595

#include <cuda/std/array>

template <size_t Phi, class Word>
__device__ cuda::std::array<Word, Phi> vec_load_words(Word* ptr) {
    // Maximum alignment is 32 bytes (LDG.256)
    constexpr auto alignment = min(sizeof(Word) * Phi, 32);
    // Provide alignment guarantee to the compiler to enforce vectorized load
    return *reinterpret_cast<cuda::std::array<Word, Phi>*>(
        __builtin_assume_aligned(ptr, alignment));
}
