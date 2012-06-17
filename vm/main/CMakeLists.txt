set(header mozart.hh)

include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${header}.gen
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -o ${CMAKE_CURRENT_BINARY_DIR}/${header}.ast
    -DMOZART_GENERATOR
    ${CMAKE_CURRENT_SOURCE_DIR}/${header}
  COMMAND generator intfimpl
    ${CMAKE_CURRENT_BINARY_DIR}/${header}.ast
    ${CMAKE_CURRENT_BINARY_DIR}/
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/${header}.gen
  DEPENDS generator
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/${header}"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT Processing ${header}
  VERBATIM)

add_custom_target(gensources
  DEPENDS ${header}.gen
  VERBATIM)

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${header}.genbi
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -o ${CMAKE_CURRENT_BINARY_DIR}/${header}.astbi
    -I ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/${header}
  COMMAND generator builtins
    ${CMAKE_CURRENT_BINARY_DIR}/${header}.astbi
    ${CMAKE_CURRENT_BINARY_DIR}/
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/${header}.genbi
  DEPENDS generator gensources
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/${header}"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT Processing builtins in ${header}
  VERBATIM)

add_custom_target(genbuiltins
  DEPENDS ${header}.genbi
  VERBATIM)

add_library(mozartvm emulate.cc memmanager.cc gcollect.cc
  unify.cc sclone.cc vm.cc coredatatypes.cc coders.cc)
add_dependencies(mozartvm gensources genbuiltins)
