# Mozart VM library

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../main" "${CMAKE_CURRENT_BINARY_DIR}/../main")

if(MINGW)
  # GTest seems to use some non-standard things :-s
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

# GTest libraries

add_library(custom_gtest STATIC IMPORTED)
set_property(TARGET custom_gtest PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest.a")

add_library(custom_gtest_main STATIC IMPORTED)
set_property(TARGET custom_gtest_main PROPERTY
             IMPORTED_LOCATION "${GTEST_BUILD_DIR}/libgtest_main.a")

include_directories("${GTEST_SRC_DIR}" "${GTEST_SRC_DIR}/include")

# The testing executable

add_executable(vmtest testutils.cc sanitytest.cc coderstest.cc utftest.cc
  smallinttest.cc floattest.cc atomtest.cc stringtest.cc virtualstringtest.cc
  bytestringtest.cc gctest.cc)
target_link_libraries(vmtest mozartvm custom_gtest custom_gtest_main)

if(NOT MINGW)
  target_link_libraries(vmtest pthread)
endif()
