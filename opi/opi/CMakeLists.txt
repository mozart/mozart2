set(OPI_FUNCTORS
    "${CMAKE_CURRENT_SOURCE_DIR}/OPI.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/Emacs.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIEnv.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIServer.oz")

set(OPI_FUNCTORS_OZF "")

foreach(FUNCTOR ${OPI_FUNCTORS})
  get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
  set(FUNCTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}/${FUNCTOR_BASENAME}.ozf")
  set(OPI_FUNCTORS_OZF ${OPI_FUNCTORS_OZF} "${FUNCTOR_OZF}")

  add_custom_command(
    OUTPUT "${FUNCTOR_OZF}"
    COMMAND ozemulator
      x-oz://system/Compile.ozf
      -c "${FUNCTOR}"
      -o "${FUNCTOR_OZF}"
    DEPENDS library "${FUNCTOR}"
    COMMENT "(compiling) ${FUNCTOR_OZF}"
    VERBATIM)
endforeach()

add_custom_target(
  opilibrary ALL
  DEPENDS ${OPI_FUNCTORS_OZF})

# Install
install(FILES ${OPI_FUNCTORS_OZF} DESTINATION share/mozart/cache/x-oz/system)
