cmake_minimum_required(VERSION 2.6)
project(testmozart)


# Configure paths
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../mozart2"
    CACHE PATH "Path to Mozart2 source directory")
set(MOZART_BUILD_DIR "${MOZART_DIR}/build"
    CACHE PATH "Path to Mozart2 build directory")

set(MOZART_LIB_DIR "${MOZART_DIR}/lib/main")
set(MOZART_COMPILER_DIR "${MOZART_DIR}/lib/compiler")

set(JAVA "/usr/bin/java"
    CACHE FILEPATH "Java executable")


# Configure compiler
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x -O3 -DNDEBUG ${CMAKE_CXX_FLAGS}")


# Boost library

find_package(Boost COMPONENTS system thread filesystem chrono REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

if(MINGW)
  # Work around a bug in MinGW
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

# Mozart VM library

add_library(mozartvm STATIC IMPORTED)
set_property(TARGET mozartvm PROPERTY
             IMPORTED_LOCATION "${MOZART_BUILD_DIR}/vm/vm/main/libmozartvm.a")

include_directories("${MOZART_DIR}/vm/vm/main" "${MOZART_BUILD_DIR}/vm/vm/main")

# Mozart VM Boost library

add_library(mozartvmboost STATIC IMPORTED)
set_property(TARGET mozartvmboost PROPERTY
             IMPORTED_LOCATION
             "${MOZART_BUILD_DIR}/vm/boostenv/main/libmozartvmboost.a")

include_directories("${MOZART_DIR}/vm/boostenv/main"
    "${MOZART_BUILD_DIR}/vm/boostenv/main")


# Generate the .cc files using the boot compiler

set(BOOTCOMPILER_JAR "${MOZART_BUILD_DIR}/bootcompiler/bootcompiler.jar")
set(BOOTCOMPILER_DEFINES -D NO_GUMP)

set(BASE_FUNCTORS
    "${MOZART_LIB_DIR}/base/Base.oz"
    "${MOZART_LIB_DIR}/boot/BootBase.oz")

add_custom_command(
  OUTPUT "Base.cc"
  COMMAND ${JAVA} -jar "${BOOTCOMPILER_JAR}"
    --baseenv
    -o "${CMAKE_CURRENT_BINARY_DIR}/Base.cc"
    -h "boostenv.hh"
    -m "${MOZART_BUILD_DIR}/vm/vm/main/"
    -m "${MOZART_BUILD_DIR}/vm/boostenv/main/"
    -b "${CMAKE_CURRENT_BINARY_DIR}/baseenv.txt"
    ${BOOTCOMPILER_DEFINES}
    ${BASE_FUNCTORS}
  DEPENDS ${BASE_FUNCTORS} "${BOOTCOMPILER_JAR}"
  COMMENT "base environment"
  VERBATIM)

file(GLOB SYS_FUNCTORS
    "${MOZART_LIB_DIR}/sys/*.oz"
    "${MOZART_LIB_DIR}/support/*.oz"
    "${MOZART_LIB_DIR}/init/Init.oz"
    "${MOZART_LIB_DIR}/sp/Error.oz"
    "${MOZART_LIB_DIR}/sp/ErrorFormatters.oz"
    "${MOZART_LIB_DIR}/op/Open.oz"
    "${MOZART_LIB_DIR}/cp/Combinator.oz"
    "${MOZART_LIB_DIR}/cp/RecordC.oz"
    "${MOZART_LIB_DIR}/dp/URL.oz"
    "${MOZART_LIB_DIR}/ap/Application.oz"
    "${MOZART_DIR}/vm/boostenv/lib/*.oz")

set(COMPILER_FUNCTORS
    "Annotate.oz" "Assembler.oz" "BackquoteMacro.oz" "Builtins.oz"
    "CodeEmitter.oz" "CodeGen.oz" "CodeStore.oz" "Main.oz" "Core.oz"
    "ForLoop.oz" "GroundZip.oz" "Macro.oz" "PrintName.oz" "RunTime.oz"
    "StaticAnalysis.oz" "Unnester.oz" "WhileLoop.oz"
    "NewAssembler.oz" "Parser.oz" "PEG.oz")

foreach(FUNCTOR ${COMPILER_FUNCTORS})
  set(SYS_FUNCTORS ${SYS_FUNCTORS} "${MOZART_COMPILER_DIR}/${FUNCTOR}")
endforeach()

set(ALL_FUNCTORS
    #"${CMAKE_CURRENT_SOURCE_DIR}/MainTest.oz" # MainTest.oz must be first
    "${CMAKE_CURRENT_SOURCE_DIR}/OPI.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/Emacs.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIServer.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIEnv.oz"
    ${SYS_FUNCTORS})

set(ALL_CCFILES "LinkerMain.cc" "Base.cc")

foreach(functor ${ALL_FUNCTORS})
  get_filename_component(basename ${functor} NAME_WE)
  set(ccfile "${basename}.cc")

  set(ALL_CCFILES ${ALL_CCFILES} ${ccfile})

  add_custom_command(
    OUTPUT ${ccfile}
    COMMAND ${JAVA} -jar "${BOOTCOMPILER_JAR}"
      -o "${CMAKE_CURRENT_BINARY_DIR}/${ccfile}"
      -h "boostenv.hh"
      -m "${MOZART_BUILD_DIR}/vm/vm/main/"
      -m "${MOZART_BUILD_DIR}/vm/boostenv/main/"
      -b "${CMAKE_CURRENT_BINARY_DIR}/baseenv.txt"
      ${BOOTCOMPILER_DEFINES}
      "${functor}"
    DEPENDS ${functor} "Base.cc"
    COMMENT "${basename}.oz"
    VERBATIM)
endforeach()

add_custom_command(
  OUTPUT LinkerMain.cc
  COMMAND ${JAVA} -jar "${BOOTCOMPILER_JAR}"
    --linker
    -o "${CMAKE_CURRENT_BINARY_DIR}/LinkerMain.cc"
    -h "boostenv.hh"
    -m "${MOZART_BUILD_DIR}/vm/vm/main/"
    -m "${MOZART_BUILD_DIR}/vm/boostenv/main/"
    -b "${CMAKE_CURRENT_BINARY_DIR}/baseenv.txt"
    ${BOOTCOMPILER_DEFINES}
    ${ALL_FUNCTORS}
  DEPENDS "Base.cc"
  COMMENT linker
  VERBATIM)

# Compile the executable

add_executable(testmozart ${ALL_CCFILES})
target_link_libraries(testmozart mozartvmboost mozartvm ${Boost_LIBRARIES})
