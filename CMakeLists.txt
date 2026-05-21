cmake_minimum_required(VERSION 3.28)
project(bloom_cuda LANGUAGES CXX CUDA)

# ── Standards ────────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# ── GPU target: Ampere sm_86 (RTX 3070 Ti) ──────────────────────────────────
set(CMAKE_CUDA_ARCHITECTURES 86)

# ── Build type (force Release if not specified) ──────────────────────────────
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# ── CUDA flags ───────────────────────────────────────────────────────────────
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --expt-relaxed-constexpr")
set(CMAKE_CUDA_FLAGS_RELEASE "-O3 --use_fast_math -lineinfo")
set(CMAKE_CUDA_FLAGS_DEBUG "-g -G -lineinfo")

# ── Dependencies ─────────────────────────────────────────────────────────────
find_package(CUDAToolkit REQUIRED)

include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# ── Core interface library ───────────────────────────────────────────────────
add_library(bloom_cuda_core INTERFACE)
target_include_directories(bloom_cuda_core INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(bloom_cuda_core INTERFACE CUDA::cudart)

# ── Tests ────────────────────────────────────────────────────────────────────
add_executable(test_hash tests/test_hash.cu)
target_link_libraries(test_hash PRIVATE bloom_cuda_core)

add_executable(test_cbf 
    tests/test_cbf.cu 
    include/bloom_filter/cbf.cu)
target_link_libraries(test_cbf PRIVATE bloom_cuda_core)

# ── Benchmarks (uncomment when ready) ────────────────────────────────────────
# add_executable(bench_all benchmarks/bench_all.cu)
# target_link_libraries(bench_all PRIVATE bloom_cuda_core)