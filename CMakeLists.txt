cmake_minimum_required(VERSION 3.20)
project(bloom_filter)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(test_bloom_filter
    src/bloom_filter.cpp
    tests/test_bloom_filter.cpp
)
target_include_directories(test_bloom_filter PRIVATE src)