cmake_minimum_required(VERSION 2.6)
project(testmozart)

# Configure paths
set(MOZART_DIR "/home/sjrd/projets/mozart")
set(BOOTCOMPILER_DIR "/home/sjrd/projets/workspace/bootcompiler")
set(SCALA "/usr/bin/scala")

# Configure compiler
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x -O3 -DNDEBUG")


# Mozart VM library

add_library(mozartvm STATIC IMPORTED)
set_property(TARGET mozartvm PROPERTY
             IMPORTED_LOCATION "${MOZART_DIR}/build/vm/main/libmozartvm.a")

include_directories("${MOZART_DIR}/vm/main" "${MOZART_DIR}/build/vm/main")


# Generate main.cc from Main.oz

add_custom_command(
  OUTPUT main.cc
  COMMAND ${SCALA} -cp "${BOOTCOMPILER_DIR}/target/scala-2.9.1/classes/"
    org.mozartoz.bootcompiler.Main
    "${CMAKE_CURRENT_SOURCE_DIR}/Main.oz"
    "${CMAKE_CURRENT_BINARY_DIR}/main.cc"
  DEPENDS Main.oz
  COMMENT Compiling Main.oz
  VERBATIM)

# Compile the executable

add_executable(testmozart main.cc)
target_link_libraries(testmozart mozartvm)
