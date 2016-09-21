# Mozart VM library

get_property(GENERATED_SOURCES_DIR GLOBAL PROPERTY GENERATED_SOURCES_DIR)
include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}/../main"
  "${GENERATED_SOURCES_DIR}")

option(BUILD_GMOCK "" OFF)
option(BUILD_GTEST "" ON)
add_subdirectory(gtest)
include_directories(${gtest_SOURCE_DIR}/include ${gtest_SOURCE_DIR})

add_executable(vmtest testutils.cc sanitytest.cc smallinttest.cc floattest.cc
  atomtest.cc gctest.cc coderstest.cc utftest.cc stringtest.cc
  virtualstringtest.cc bytestringtest.cc)
target_link_libraries(vmtest mozartvm gtest gtest_main)

if(NOT MINGW)
  target_link_libraries(vmtest pthread)
endif()
