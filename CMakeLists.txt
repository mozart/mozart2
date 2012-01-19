cmake_minimum_required(VERSION 2.6)
project(MOZART)

set(CMAKE_CXX_FLAGS "-Wall -std=c++0x -O3 -DNDEBUG")

add_subdirectory(vm)
