set(interface_headers coreinterfaces.hh)

foreach(header ${interface_headers})
add_custom_target(${header}.gen
  COMMAND ${LLVM_BUILD_DIR}/bin/clang++ -std=c++0x -femit-ast -o${header}.ast -DMOZART_GENERATOR ${CMAKE_CURRENT_SOURCE_DIR}/${header}
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/../../generator/main/generator ${header}.ast
  DEPENDS ${header}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  COMMENT Generating Interfaces for ${header}
  VERBATIM)
endforeach(header)
string(REPLACE ".hh" ".hh.gen" interface_headers_gen ${interface_headers})

include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_executable(vm main.cc smallint.cc codearea.cc emulate.cc type.cc vm.cc
               store.cc corebuiltins.cc coreinterfaces.cc
               callables.cc variables.cc boolean.cc atom.cc)
add_dependencies(vm ${interface_headers_gen})