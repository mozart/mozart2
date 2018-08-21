# Boost library

find_package(Boost COMPONENTS random system thread filesystem chrono REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

separate_arguments(SPLIT_CXX_FLAGS UNIX_COMMAND "${CMAKE_CXX_FLAGS}")
set(MOZART_GENERATOR_FLAGS "${MOZART_GENERATOR_FLAGS}" "${SPLIT_CXX_FLAGS}")

# GMP (optional)
include(FindGMP)
if(GMP_FOUND)
  include_directories(${GMP_INCLUDE_DIR})
  add_definitions(-DUSE_GMP)
  set(MOZART_GENERATOR_FLAGS "${MOZART_GENERATOR_FLAGS}" -DUSE_GMP)
endif()

if(WIN32)
  # Boost requires this
  add_definitions(-D_WIN32_WINNT=0x0501)
  set(MOZART_GENERATOR_FLAGS "${MOZART_GENERATOR_FLAGS}" -D_WIN32_WINNT=0x0501)
endif()

if(MINGW)
  # Work around a bug in MinGW
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x "
         CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  set(CXX_STD_OPT -std=gnu++0x)
else()
  set(CXX_STD_OPT -std=c++0x)
endif()

# Mozart VM library

get_property(GENERATED_SOURCES_DIR GLOBAL PROPERTY GENERATED_SOURCES_DIR)
include_directories("${MOZART_SOURCE_DIR}/vm/vm/main" "${GENERATED_SOURCES_DIR}")
link_directories("${MOZART_BINARY_DIR}/vm/vm/main")

set(GENERATED_BOOSTSOURCES_CACHED_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cached/)
set(GENERATED_BOOSTSOURCES_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated/)

# Generate sources
find_program(clang_bin clang++)

add_custom_command(
  OUTPUT ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenv.gen

  # First pass: generate data types and interfaces
  COMMAND ${clang_bin}
    -o ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenv.ast
    -I ${Boost_INCLUDE_DIRS}
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../../vm/main
    -DMOZART_GENERATOR
    ${MOZART_GENERATOR_FLAGS}
    ${CMAKE_CURRENT_SOURCE_DIR}/boostenv.hh
  COMMAND generator intfimpl
    ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenv.ast
    ${GENERATED_BOOSTSOURCES_BINARY_DIR}/

  # Second pass: generate builtin information
  COMMAND ${clang_bin}
    -o ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenvmodules.astbi
    -I ${Boost_INCLUDE_DIRS}
    -I ${GENERATED_BOOSTSOURCES_BINARY_DIR}
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../../vm/main
    -I ${GENERATED_BOOSTSOURCES_BINARY_DIR}/../../vm/main
    -DMOZART_BUILTIN_GENERATOR
    ${MOZART_GENERATOR_FLAGS}
    ${CMAKE_CURRENT_SOURCE_DIR}/boostenvmodules.hh
  COMMAND generator builtins
    ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenvmodules.astbi
    ${GENERATED_BOOSTSOURCES_BINARY_DIR}/
    boostenvbuiltins

  # Tag
  COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_BOOSTSOURCES_BINARY_DIR}/boostenv.gen

  DEPENDS generator gensources
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/boostenvmodules.hh"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT "Generate sources for boostenv"
  VERBATIM)


# Use the cached files if they exist.

if(EXISTS ${GENERATED_BOOSTSOURCES_CACHED_DIR}/boostenv.gen)
    set(GENERATED_BOOSTSOURCES_DIR ${GENERATED_BOOSTSOURCES_CACHED_DIR})
else()
    set(GENERATED_BOOSTSOURCES_DIR ${GENERATED_BOOSTSOURCES_BINARY_DIR})
    file(MAKE_DIRECTORY ${GENERATED_BOOSTSOURCES_BINARY_DIR})
endif()
set_property(GLOBAL PROPERTY GENERATED_BOOSTSOURCES_DIR "${GENERATED_BOOSTSOURCES_DIR}")

add_custom_target(genboostsources
  DEPENDS ${GENERATED_BOOSTSOURCES_DIR}/boostenv.gen
  VERBATIM)


# Include the generated files in the source archive.

set_property(GLOBAL APPEND PROPERTY SRCS_INSTALLED_DIRS
    "${GENERATED_BOOSTSOURCES_DIR}" "/vm/boostenv/main/cached/")

if(DIST_TARGET_ENABLED)
    add_dependencies(dist genboostsources)
endif()

# Boost environment library
include_directories(${GENERATED_BOOSTSOURCES_DIR})

add_library(mozartvmboost boostvm.cc boostenvmodules.cc)
add_dependencies(mozartvmboost genboostsources)
