cmake_minimum_required(VERSION 2.6)
PROJECT(MOZART)

################################################################################
# GTest - http://code.google.com/p/googletest/
################################################################################
enable_testing(true)
include_directories(${GTEST_SRC_DIR}/include ${GTEST_SRC_DIR})

################################################################################
# MOZART
################################################################################
add_executable(ut ut_source.cpp source.cpp)
target_link_libraries(ut pthread "${GTEST_BUILD_DIR}/libgtest.a" "${GTEST_BUILD_DIR}/libgtest_main.a")
