# Boost library

find_package(Boost 1.49 COMPONENTS thread REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

# Mozart VM library

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../../vm/main"
    "${CMAKE_CURRENT_BINARY_DIR}/../../vm/main")

link_directories("${CMAKE_CURRENT_BINARY_DIR}/../../vm/main")

# Boost builtins

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/boostenv.genbi
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -o ${CMAKE_CURRENT_BINARY_DIR}/boostenv.astbi
    -I ${CMAKE_CURRENT_BINARY_DIR}
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../../vm/main
    -I ${CMAKE_CURRENT_BINARY_DIR}/../../vm/main
    ${CMAKE_CURRENT_SOURCE_DIR}/boostenv.hh
  COMMAND generator builtins
    ${CMAKE_CURRENT_BINARY_DIR}/boostenv.astbi
    ${CMAKE_CURRENT_BINARY_DIR}/
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/boostenv.genbi
  DEPENDS generator gensources
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/boostenv.hh"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT Processing builtins in boostenv.hh
  VERBATIM)

add_custom_target(genboostbuiltins
  DEPENDS boostenv.genbi
  VERBATIM)

# Boost environment library

add_library(mozartvmboost boostenv.cc)
add_dependencies(mozartvmboost genboostbuiltins)
