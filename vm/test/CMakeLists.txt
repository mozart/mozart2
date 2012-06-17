# Mozart VM library

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../main" "${CMAKE_CURRENT_BINARY_DIR}/../main")

# GTest libraries

add_library(custom_gtest STATIC IMPORTED)
set_property(TARGET custom_gtest PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest.a")

add_library(custom_gtest_main STATIC IMPORTED)
set_property(TARGET custom_gtest_main PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest_main.a")

include_directories("${GTEST_SRC_DIR}" "${GTEST_SRC_DIR}/include")

# The testing executable

add_executable(vmtest smallinttest.cc floattest.cc testutils.cc atomtest.cc
                      bytestringtest.cc coderstest.cc matchtest.cc sanitytest.cc
                      stringtest.cc utftest.cc virtualstringtest.cc)
target_link_libraries(vmtest mozartvm pthread custom_gtest custom_gtest_main)
