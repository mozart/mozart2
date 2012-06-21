cmake_minimum_required(VERSION 2.6)
project(testmozart)


# Configure paths
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mozart2"
    CACHE PATH "Path to Mozart2 source directory")
set(MOZART_BUILD_DIR "${MOZART_DIR}/build"
    CACHE PATH "Path to Mozart2 build directory")

set(BOOTCOMPILER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mozart2-bootcompiler"
    CACHE PATH "Path to Mozart2 boot compiler directory")

set(JAVA "/usr/bin/java"
    CACHE PATH "Java executable")


# Configure compiler
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x -O3 -DNDEBUG")


# Boost library

find_package(Boost 1.49 COMPONENTS system thread REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

# Mozart VM library

add_library(mozartvm STATIC IMPORTED)
set_property(TARGET mozartvm PROPERTY
             IMPORTED_LOCATION "${MOZART_DIR}/build/vm/main/libmozartvm.a")

include_directories("${MOZART_DIR}/vm/main" "${MOZART_BUILD_DIR}/vm/main")

# Mozart VM Boost library

add_library(mozartvmboost STATIC IMPORTED)
set_property(TARGET mozartvmboost PROPERTY
             IMPORTED_LOCATION
             "${MOZART_DIR}/build/boostenv/main/libmozartvmboost.a")

include_directories("${MOZART_DIR}/boostenv/main"
    "${MOZART_BUILD_DIR}/boostenv/main")


# Generate main.cc from Main.oz

file(GLOB SYS_FUNCTORS
    "${MOZART_DIR}/lib/sys/*.oz"
    "${MOZART_DIR}/boostenv/lib/*.oz")

add_custom_command(
  OUTPUT main.cc
  COMMAND ${JAVA} -jar
    "${BOOTCOMPILER_DIR}/target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar"
    -o "${CMAKE_CURRENT_BINARY_DIR}/main.cc"
    -m "${MOZART_BUILD_DIR}/boostenv/main/"
    -b "${MOZART_BUILD_DIR}/lib/base/BaseBuilt.oz"
    -b "${MOZART_DIR}/lib/boot/BootBase.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/Main.oz"
    ${SYS_FUNCTORS}
  DEPENDS Main.oz ${SYS_FUNCTORS}
  COMMENT Compiling Main.oz
  VERBATIM)

# Compile the executable

add_executable(testmozart main.cc)
target_link_libraries(testmozart mozartvmboost mozartvm ${Boost_LIBRARIES})
