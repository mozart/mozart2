# Mozart VM library

get_property(GENERATED_SOURCES_DIR GLOBAL PROPERTY GENERATED_SOURCES_DIR)
include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}/../main"
  "${GENERATED_SOURCES_DIR}")

if(MINGW)
  # GTest seems to use some non-standard things :-s
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x "
         CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

# GTest libraries
# Allow to use shared libraries, but prefer static ones when possible
# to avoid missing libraries at execution time.
find_library(GTEST_LIBRARY NAME gtest.a gtest.lib gtest PATHS "${GTEST_BUILD_DIR}")
find_library(GTEST_MAIN_LIBRARY NAME gtest_main.a gtest_main.lib gtest_main PATHS "${GTEST_BUILD_DIR}")
if("${GTEST_LIBRARY}" MATCHES "GTEST_LIBRARY-NOTFOUND")
    message(FATAL_ERROR "Could not find gtest library in ${GTEST_BUILD_DIR}")
endif()
if("${GTEST_MAIN_LIBRARY}" MATCHES "GTEST_MAIN_LIBRARY-NOTFOUND")
    message(FATAL_ERROR "Could not find gtest_main library in ${GTEST_BUILD_DIR}")
endif()

include_directories("${GTEST_SRC_DIR}" "${GTEST_SRC_DIR}/include")

# The testing executable

add_executable(vmtest testutils.cc sanitytest.cc smallinttest.cc floattest.cc
  atomtest.cc gctest.cc coderstest.cc utftest.cc stringtest.cc
  virtualstringtest.cc bytestringtest.cc)
target_link_libraries(vmtest mozartvm "${GTEST_LIBRARY}" "${GTEST_MAIN_LIBRARY}")

if(NOT MINGW)
  target_link_libraries(vmtest pthread)
endif()
