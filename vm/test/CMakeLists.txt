
set(SRC "${CMAKE_CURRENT_SOURCE_DIR}/../main")
include_directories(${SRC} ${GTEST_SRC_DIR}/include ${GTEST_SRC_DIR} ${CMAKE_CURRENT_BINARY_DIR}/../main)

add_executable(vmtest factorial_tests.cpp
		      ../main/emulate.cc
		      ../main/vm.cc
		      ../main/corebuiltins.cc
		      ../main/memmanager.cc
		      ../main/gcollect.cc)

target_link_libraries(vmtest pthread "${GTEST_BUILD_DIR}/libgtest.a" "${GTEST_BUILD_DIR}/libgtest_main.a")
