cmake_minimum_required(VERSION 2.8)
project(MOZARTVM)

include(ExternalProject)
set(ep_base "${CMAKE_BINARY_DIR}/externals")
set_property(DIRECTORY PROPERTY "EP_BASE" ${ep_base})

set(DEFAULT_LLVM_SRC_DIR "${ep_base}/Source/llvm")
set(DEFAULT_LLVM_BUILD_DIR "${ep_base}/Build/llvm")
set(LLVM_SRC_DIR ${DEFAULT_LLVM_SRC_DIR} CACHE PATH "Path to LLVM sources (with Clang)")
set(LLVM_BUILD_DIR ${DEFAULT_LLVM_BUILD_DIR} CACHE PATH "Path to LLVM build (with Clang)")

set(MOZART_GENERATOR_FLAGS "${DEFAULT_MOZART_GENERATOR_FLAGS}" CACHE STRING
    "Additional flags for the generator parser (clang)")

add_compile_options(-std=c++0x)

add_subdirectory(generator)

add_compile_options(-Wall)

add_subdirectory(vm)
add_subdirectory(boostenv)
