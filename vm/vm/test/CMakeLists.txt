# Mozart VM library

include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}/../main"
  "${CMAKE_CURRENT_BINARY_DIR}/../main")

if(MINGW)
  # GTest seems to use some non-standard things :-s
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x "
         CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
  include_directories(/usr/lib/c++/v1)
endif()

# GTest libraries

find_library(GTEST_LIBRARY
    NAMES libgtest.a gtest libgtest
    HINTS "${GTEST_BUILD_DIR}"
)

find_library(GTEST_MAIN_LIBRARY
    NAMES libgtest_main.a gtest_main libgtest_main
    HINTS "${GTEST_BUILD_DIR}"
)

include_directories("${GTEST_SRC_DIR}" "${GTEST_SRC_DIR}/include")

# The testing executable

set(VMTEST_SRCS testutils.cc sanitytest.cc smallinttest.cc floattest.cc
  atomtest.cc gctest.cc)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  message(WARNING "String tests are disabled on this platform")
else()
  list(APPEND VMTEST_SRCS coderstest.cc utftest.cc stringtest.cc
    virtualstringtest.cc bytestringtest.cc)
endif()

add_executable(vmtest ${VMTEST_SRCS})
target_link_libraries(vmtest mozartvm ${GTEST_LIBRARY} ${GTEST_MAIN_LIBRARY})

if(NOT MINGW)
  target_link_libraries(vmtest pthread)
endif()
