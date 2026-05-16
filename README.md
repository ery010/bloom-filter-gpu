# Bloom Filter Optimization on GPU Architecture

A CUDA implementation of
[*Optimizing Bloom Filters for Modern GPU Architectures* (Jünger et al., 2025)](https://arxiv.org/pdf/2512.15595).

## Overview

Bloom filters are probabilistic data structures for approximate membership
queries. While space-efficient, their probabilistic nature means that 100% accuracy is not guaranteed, and false positives are possible (false negatives are not).

This project implements Bloom filter variants optimized for modern GPU architectures. The paper names 3 optimization strategies:
* Horizontal & Vertical Vectorization
* Key Pattern Generation
* Adaptive Thread Cooperation

The algorithms implemented in this project are:
* `CBF`: Classical Bloom Filter
* `BBF`: Blocked Bloom Filter
* `SBF`: Sectorized Bloom Filter
* `CSBF`: Cache-Sectorized Bloom Filter


## Project Structure
```
bloom-filter-gpu/
├── include/ 
|   └── bloom_filter/
|       ├── CBF.cuh
|       ├── BBF.cuh
|       ├── SBF.cuh
│       └── CSBF.cuh
|
├── src/
│   ├── bloom_filter.h
│   └── bloom_filter.cpp
|
├── tests/
│   └── test_bloom_filter.cpp
|
└── CMakeLists.txt
```
## Building

### Prerequisites

- CMake 3.20+
- Visual Studio Build Tools with "Desktop development with C++" (Windows)
- NVIDIA CUDA Toolkit 12.4+ with WSL2 (for GPU targets)

### CPU Build

```bash
cmake -S . -B build
cmake --build build
.\build\Debug\test_bloom_filter.exe
```

## References

Jünger et al., *Optimizing Bloom Filters for Modern GPU Architectures*, ACM ICS
2026. https://arxiv.org/abs/2512.15595