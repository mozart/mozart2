set(PANEL_FUNCTOR
    "${CMAKE_CURRENT_SOURCE_DIR}/Panel.oz")

set(PANEL_OZF "${CMAKE_CURRENT_BINARY_DIR}/Panel.ozf")

add_custom_command(
  OUTPUT "${PANEL_OZF}"
  COMMAND ozemulator
    --home "${MOZART_BUILD_DIR}"
    x-oz://system/Compile.ozf
    -c "${PANEL_FUNCTOR}" -o "${PANEL_OZF}"
  DEPENDS library "${PANEL_FUNCTOR}"
  COMMENT "(compiling) ${PANEL_OZF}"
  VERBATIM)

add_custom_target(
  panel ALL
  DEPENDS "${PANEL_OZF}")

# Install
install(FILES "${PANEL_OZF}"
        DESTINATION share/mozart/cache/x-oz/system)
