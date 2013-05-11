set(INSPECTOR_FUNCTORS
    "${CMAKE_CURRENT_SOURCE_DIR}/InspectorMain.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/InspectorOptions.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/Reflection.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/CreateObjects.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/DrawObjects.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/GraphicSupport.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/Helper.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/LayoutObjects.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/RelationManager.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/StoreListener.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/TreeNodes.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/treewidget/TreeWidget.oz")

set(INSPECTOR_FUNCTOR
    "${CMAKE_CURRENT_SOURCE_DIR}/Inspector.oz")

set(INSPECTOR_SUB_DIR "${CMAKE_CURRENT_BINARY_DIR}/inspector")
file(MAKE_DIRECTORY "${INSPECTOR_SUB_DIR}")

set(INSPECTOR_FUNCTORS_OZF "")

foreach(FUNCTOR ${INSPECTOR_FUNCTORS})
  get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
  set(FUNCTOR_OZF "${INSPECTOR_SUB_DIR}/${FUNCTOR_BASENAME}.ozf")

  set(INSPECTOR_FUNCTORS_OZF ${INSPECTOR_FUNCTORS_OZF} "${FUNCTOR_OZF}")

  add_custom_command(
    OUTPUT "${FUNCTOR_OZF}"
    COMMAND ozemulator
      --home "${MOZART_BUILD_DIR}"
      x-oz://system/Compile.ozf
      -c "${FUNCTOR}"
      -o "${FUNCTOR_OZF}"
    DEPENDS library "${FUNCTOR}"
    COMMENT "(compiling) ${FUNCTOR_OZF}"
    VERBATIM)
endforeach()

set(INSPECTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}/Inspector.ozf")

add_custom_command(
  OUTPUT "${INSPECTOR_OZF}"
  COMMAND ozemulator
    --home "${MOZART_BUILD_DIR}"
    x-oz://system/Compile.ozf
    -c "${INSPECTOR_FUNCTOR}" -o "${INSPECTOR_OZF}"
  DEPENDS library "${INSPECTOR_FUNCTOR}"
  COMMENT "(compiling) ${INSPECTOR_OZF}"
  VERBATIM)

add_custom_target(
  inspector ALL
  DEPENDS ${INSPECTOR_FUNCTORS_OZF} "${INSPECTOR_OZF}")

# Supplementary files

set(SRC_IMAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/images")
set(BIN_IMAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/images/inspector")

file(GLOB SUPPLEMENTARY_FILES RELATIVE "${SRC_IMAGE_DIR}"
  "${SRC_IMAGE_DIR}/*.xbm"
  "${SRC_IMAGE_DIR}/*.jpg")

file(MAKE_DIRECTORY "${BIN_IMAGE_DIR}")

set(TARGET_SUPPLEMENTARY_FILES "")

foreach(SUPP_FILE ${SUPPLEMENTARY_FILES})
  set(SRC_FILE "${SRC_IMAGE_DIR}/${SUPP_FILE}")
  set(TARGET_FILE "${BIN_IMAGE_DIR}/${SUPP_FILE}")
  set(TARGET_SUPPLEMENTARY_FILES ${TARGET_SUPPLEMENTARY_FILES} "${TARGET_FILE}")

  add_custom_command(
    TARGET inspector POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${SRC_FILE}" "${TARGET_FILE}"
    VERBATIM)
endforeach()

# Install
install(FILES ${INSPECTOR_FUNCTORS_OZF}
        DESTINATION share/mozart/cache/x-oz/system/inspector)
install(FILES "${INSPECTOR_OZF}"
        DESTINATION share/mozart/cache/x-oz/system)

install(FILES ${TARGET_SUPPLEMENTARY_FILES}
        DESTINATION share/mozart/cache/x-oz/system/images/inspector)
