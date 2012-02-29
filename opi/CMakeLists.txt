cmake_minimum_required(VERSION 2.6)
project(testmozart)

set(MOZART_DIR "/home/sjrd/projets/mozart")

set(CMAKE_CXX_FLAGS "-Wall -std=c++0x -O3 -DNDEBUG")

add_library(mozartvm STATIC IMPORTED)
set_property(TARGET mozartvm PROPERTY
             IMPORTED_LOCATION "${MOZART_DIR}/build/vm/main/libmozartvm.a")

include_directories("${MOZART_DIR}/vm/main" "${MOZART_DIR}/build/vm/main")

add_executable(testmozart main.cc)
target_link_libraries(testmozart mozartvm)
