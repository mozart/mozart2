set(CLANG_SRC_DIR "${LLVM_SRC_DIR}/tools/clang")
set(CLANG_BUILD_DIR "${LLVM_BUILD_DIR}/tools/clang")

add_definitions(-D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS)

set(CMAKE_CXX_FLAGS "-Wall -Wno-enum-compare -Wno-strict-aliasing -std=gnu++0x ${CMAKE_CXX_FLAGS}")

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

# Depending on the platform and version of clang, the clang library will
# be named libclang or liblibclang. Now we detect that.
find_library(CLANG_LIBRARY
  NAMES clang libclang
  PATHS "${LLVM_BUILD_DIR}/lib"
  NO_DEFAULT_PATH)
if("${CLANG_LIBRARY}" MATCHES "CLANG_LIBRARY-NOTFOUND")
  message(FATAL_ERROR "Could not find clang library in ${LLVM_BUILD_DIR}")
endif()

include_directories(
  "${LLVM_SRC_DIR}/include"
  "${LLVM_BUILD_DIR}/include"
  "${CLANG_SRC_DIR}/include"
  "${CLANG_BUILD_DIR}/include")
link_directories("${LLVM_BUILD_DIR}/lib")
add_executable(generator generator.cc interfaces.cc implementations.cc
  builtins.cc utils.cc)
target_link_libraries(generator "${CLANG_LIBRARY}")
