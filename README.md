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
|       ├── cbf.cu
|       ├── bbf.cu
|       ├── sbf.cu
|       ├── csbf.cu
|       ├── cbf.cuh
|       ├── bbf.cuh
|       ├── sbf.cuh
│       └── csbf.cuh
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

## Implementation Progress

### Bloom Filter Core
- [x] Hash function defintions (`hash_function.cuh`)
- [x] Classical Bloom Filter (`cbf.cuh` / `cbf.cu`)
- [x] Blocked Bloom Filter (`bbf.cuh` / `bbf.cu`)
- [ ] Sectorized Bloom Filter (`sbf.cuh` / `sbf.cu`)
- [ ] Cache-Sectorized Bloom Filter (`csbf.cuh` / `csbf.cu`)

### Tests
- [x] Hash function test
    - [x] Verify xxHash CUDA implementation against official implementation
- [x] Classical Bloom Filter test
    - [x] Insertions
    - [x] Key lookups
    - [x] False positive rate
    - [x] No false negatives

- [ ] Blocked Bloom Filter test
    - [x] Insertions
    - [ ] Key lookups
    - [ ] False positive rate
    - [ ] No false negatives

- [x] Sectorized Bloom Filter test
    - [ ] Insertions
    - [ ] Key lookups
    - [ ] False positive rate
    - [ ] No false negatives

- [ ] Cache-Sectorized Bloom Filter test
    - [ ] Insertions
    - [ ] Key lookups
    - [ ] False positive rate
    - [ ] No false negatives

## References

Jünger et al., *Optimizing Bloom Filters for Modern GPU Architectures*, ACM ICS
2026. https://arxiv.org/abs/2512.15595