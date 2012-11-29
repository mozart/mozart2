# Find the emacs program, which is the compiler for .el files

find_program(EMACS NAMES emacs xemacs Aquamacs
  # Usual paths for emacs on mac os x
  HINTS "/Applications/Aquamacs.app/Contents/MacOS/Aquamacs"
)

if(NOT EMACS)
  message(WARNING "Emacs executable not found")
else()
  message(STATUS "Using emacs from: ${EMACS}")
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
      COMMAND ${EMACS}
        -eval "(setq load-path (append load-path '(\"${CMAKE_CURRENT_SOURCE_DIR}\")))"
        ${EMACS_OPTIONS}  "${el_file}"
      COMMAND ${CMAKE_COMMAND} -E rename "${gen_file}" "${tgt_file}"
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      COMMENT "Generating: ${elc_file}"
      VERBATIM)
  endforeach()

  add_custom_target(emacs_mode ALL DEPENDS ${ALL_ELC_FILES} VERBATIM)

  # Install

  install(FILES ${ALL_ELC_FILES} DESTINATION share/mozart/elisp)
  install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/oz" DESTINATION bin)
endif()
