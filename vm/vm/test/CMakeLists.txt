# Mozart VM library

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../main" "${CMAKE_CURRENT_BINARY_DIR}/../main")

# GTest libraries

add_library(gtest STATIC IMPORTED)
set_property(TARGET gtest PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest.a")

add_library(gtest_main STATIC IMPORTED)
set_property(TARGET gtest_main PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest_main.a")

include_directories("${GTEST_SRC_DIR}" "${GTEST_SRC_DIR}/include")

# The testing executable

add_executable(vmtest smallinttest.cc)
target_link_libraries(vmtest mozartvm pthread gtest gtest_main)
