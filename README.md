# Bloom Filter GPU

A GPU-accelerated Bloom filter implemented in CUDA, based on the paper
*Optimizing Bloom Filters for Modern GPU Architectures* (Jünger et al., 2025).

## Overview

Bloom filters are a probabilistic data structure for approximate membership
queries used in databases, data analytics, and genomics. While CPU
implementations are well studied, GPU designs remain underexplored. This project
implements and optimizes Bloom filter variants for modern GPU architectures,
following the design space explored in the paper across three dimensions:
vectorization, thread cooperation, and compute latency.

The C++ CPU implementation serves as a reference baseline and correctness oracle
for the CUDA port.

## Project Structure
```
bloom-filter-gpu/
├── src/
│   ├── bloom_filter.h
│   └── bloom_filter.cpp
├── tests/
│   └── test_bloom_filter.cpp
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