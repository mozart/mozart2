cmake_minimum_required(VERSION 2.8)
project(MOZART_EMACS NONE)

message(STATUS "From mozart-emacs")

set(EMACS_PROGRAM "/Applications/Aquamacs.app/Contents/MacOS/Aquamacs")
set(EMACS_OPTIONS -q -batch -f batch-byte-compile)
set(EMACS_MODE_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/oz.el"
  "${CMAKE_CURRENT_SOURCE_DIR}/oz-server.el"
  "${CMAKE_CURRENT_SOURCE_DIR}/oz-extra.el"
  "${CMAKE_CURRENT_SOURCE_DIR}/mozart.el"
)

set(ALL_ELC_FILES)
foreach(el_file ${EMACS_MODE_SRCS})
  get_filename_component(basename ${el_file} NAME_WE)
  get_filename_component(srcpath ${el_file} PATH)
  set(elc_file "${basename}.elc")
  set(gen_file "${srcpath}/${elc_file}")
  set(tgt_file "${CMAKE_CURRENT_BINARY_DIR}/${elc_file}")
  set(ALL_ELC_FILES ${ALL_ELC_FILES} ${tgt_file})

  add_custom_command(
    OUTPUT ${tgt_file}
    COMMAND ${EMACS_PROGRAM} -L ${CMAKE_CURRENT_SOURCE_DIR} ${EMACS_OPTIONS}  "${el_file}"
    COMMAND ${CMAKE_COMMAND} -E rename "${gen_file}" "${tgt_file}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating: ${elc_file}"
    VERBATIM)
endforeach()

install(FILES ${ALL_ELC_FILES}
  DESTINATION bin)

message(STATUS "All files: ${ALL_ELC_FILES}")
add_custom_target(emacs_mode
  DEPENDS ${ALL_ELC_FILES}
  VERBATIM)
