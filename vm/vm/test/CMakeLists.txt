# Mozart VM library

get_property(GENERATED_SOURCES_DIR GLOBAL PROPERTY GENERATED_SOURCES_DIR)
include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}/../main"
  "${GENERATED_SOURCES_DIR}")

set(BUILD_GMOCK OFF)
set(INSTALL_GTEST OFF)
add_subdirectory(gtest EXCLUDE_FROM_ALL)
# Third-party code: its warnings are not ours to fix.
target_compile_options(gtest PRIVATE -w)
target_compile_options(gtest_main PRIVATE -w)
include_directories(${gtest_SOURCE_DIR}/include ${gtest_SOURCE_DIR})

add_executable(vmtest testutils.cc sanitytest.cc smallinttest.cc floattest.cc
  atomtest.cc gctest.cc coderstest.cc utftest.cc stringtest.cc
  virtualstringtest.cc bytestringtest.cc)
target_link_libraries(vmtest mozartvm gtest_main) # gtest_main links gtest
add_test(vmtest vmtest)
add_dependencies(check vmtest)

if(NOT MINGW)
  target_link_libraries(vmtest pthread)
endif()
