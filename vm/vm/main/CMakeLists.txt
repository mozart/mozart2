set(interface_headers mozart.hh)

foreach(header ${interface_headers})
add_custom_command(
  OUTPUT ${header}.gen
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast -o${header}.ast -DMOZART_GENERATOR ${CMAKE_CURRENT_SOURCE_DIR}/${header}
  COMMAND generator ${header}.ast
  COMMAND ${CMAKE_COMMAND} -E touch ${header}.gen
  DEPENDS generator
  IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/${header}"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  COMMENT Generating Interfaces for ${header}
  VERBATIM)
endforeach(header)

string(REPLACE ".hh" ".hh.gen" interface_headers_gen "${interface_headers}")

include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_custom_target(gensources
  DEPENDS ${interface_headers_gen}
  VERBATIM)

add_library(mozartvm emulate.cc corebuiltins.cc memmanager.cc gcollect.cc
  unify.cc space.cc)
add_dependencies(mozartvm gensources)
