set(CLANG_SRC_DIR "${LLVM_SRC_DIR}/tools/clang")
set(CLANG_BUILD_DIR "${LLVM_BUILD_DIR}/tools/clang")

add_definitions(-D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS)

set(CMAKE_CXX_FLAGS "-Wall -Wno-enum-compare -Wno-strict-aliasing -std=gnu++0x ${CMAKE_CXX_FLAGS}")

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

include_directories(
  "${LLVM_SRC_DIR}/include"
  "${LLVM_BUILD_DIR}/include"
  "${CLANG_SRC_DIR}/include"
  "${CLANG_BUILD_DIR}/include")
link_directories("${LLVM_BUILD_DIR}/lib")
add_executable(generator generator.cc interfaces.cc implementations.cc
  builtins.cc utils.cc)
target_link_libraries(generator libclang)
