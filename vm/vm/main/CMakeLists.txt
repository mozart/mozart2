include_directories(${CMAKE_CURRENT_BINARY_DIR})

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(MOZART_GENERATOR_FLAGS "-I/usr/lib/c++/v1")
  include_directories(/usr/lib/c++/v1)
endif()

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/mozart.gen

  # First pass: generate data types and interfaces
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast
    -Wno-invalid-noreturn -Wno-return-type
    -o ${CMAKE_CURRENT_BINARY_DIR}/mozart.ast
    -DMOZART_GENERATOR
    ${MOZART_GENERATOR_FLAGS}
    ${CMAKE_CURRENT_SOURCE_DIR}/mozart.hh
  COMMAND generator intfimpl
    ${CMAKE_CURRENT_BINARY_DIR}/mozart.ast
    ${CMAKE_CURRENT_BINARY_DIR}/

  # Second pass: generate builtin information
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

  # Tag
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/mozart.gen

  DEPENDS generator
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/coremodules.hh"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT "Generate sources for mozart"
  VERBATIM)

add_custom_target(gensources
  DEPENDS mozart.gen
  VERBATIM)

add_library(mozartvm emulate.cc memmanager.cc gcollect.cc
  unify.cc sclone.cc vm.cc coredatatypes.cc coders.cc properties.cc
  coremodules.cc)
add_dependencies(mozartvm gensources)
