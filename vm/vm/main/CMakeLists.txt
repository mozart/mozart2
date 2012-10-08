include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/mozart.gen
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -Wno-invalid-noreturn -Wno-return-type
    -o ${CMAKE_CURRENT_BINARY_DIR}/mozart.ast
    -DMOZART_GENERATOR
    ${MOZART_GENERATOR_FLAGS}
    ${CMAKE_CURRENT_SOURCE_DIR}/mozart.hh
  COMMAND generator intfimpl
    ${CMAKE_CURRENT_BINARY_DIR}/mozart.ast
    ${CMAKE_CURRENT_BINARY_DIR}/
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/mozart.gen
  DEPENDS generator
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/mozart.hh"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT Processing mozart.hh
  VERBATIM)

add_custom_target(gensources
  DEPENDS mozart.gen
  VERBATIM)

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/coremodules.genbi
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -Wno-invalid-noreturn -Wno-return-type
    -o ${CMAKE_CURRENT_BINARY_DIR}/coremodules.astbi
    -I ${CMAKE_CURRENT_BINARY_DIR}
    -DMOZART_BUILTIN_GENERATOR
    ${MOZART_GENERATOR_FLAGS}
    ${CMAKE_CURRENT_SOURCE_DIR}/coremodules.hh
  COMMAND generator builtins
    ${CMAKE_CURRENT_BINARY_DIR}/coremodules.astbi
    ${CMAKE_CURRENT_BINARY_DIR}/
    mozartbuiltins
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/mozart.gen # hack for dependency management
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/coremodules.genbi
  DEPENDS generator gensources
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/coremodules.hh"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT Processing builtins in coremodules.hh
  VERBATIM)

add_custom_target(genbuiltins
  DEPENDS coremodules.genbi
  VERBATIM)

add_library(mozartvm emulate.cc memmanager.cc gcollect.cc
  unify.cc sclone.cc vm.cc coredatatypes.cc coders.cc properties.cc
  coremodules.cc)
add_dependencies(mozartvm gensources genbuiltins)
