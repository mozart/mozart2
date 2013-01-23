# Configure paths
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(MOZART_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/..")

set(MOZART_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/main")
set(MOZART_COMPILER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/compiler")

# ---------------------------------------------------------------------------- #
# Find all the files we need to compile                                        #
# ---------------------------------------------------------------------------- #

set(BASE_FUNCTOR "${MOZART_LIB_DIR}/base/Base.oz")
set(RUNTIME_FUNCTOR "${MOZART_COMPILER_DIR}/RunTime.oz")
set(INIT_FUNCTOR "${MOZART_LIB_DIR}/init/Init.oz")

set(SYS_FUNCTORS
    "${MOZART_LIB_DIR}/sys/Property.oz"
    "${MOZART_LIB_DIR}/sys/Space.oz"
    "${MOZART_LIB_DIR}/sys/Pickle.oz"
    "${MOZART_LIB_DIR}/support/CompilerSupport.oz"
    "${MOZART_LIB_DIR}/support/ErrorListener.oz"
    "${MOZART_LIB_DIR}/support/Listener.oz"
    "${MOZART_LIB_DIR}/support/Narrator.oz"
    "${MOZART_LIB_DIR}/support/ObjectSupport.oz"
    "${MOZART_LIB_DIR}/support/Type.oz"
    "${MOZART_LIB_DIR}/sp/Error.oz"
    "${MOZART_LIB_DIR}/sp/ErrorFormatters.oz"
    "${MOZART_LIB_DIR}/op/Open.oz"
    "${MOZART_LIB_DIR}/cp/Combinator.oz"
    "${MOZART_LIB_DIR}/cp/RecordC.oz"
    "${MOZART_LIB_DIR}/ap/Application.oz"
    "${MOZART_DIR}/vm/boostenv/lib/OS.oz")

set(COMPILER_FUNCTORS_0
    "Annotate.oz" "Assembler.oz" "BackquoteMacro.oz" "Builtins.oz"
    "CodeEmitter.oz" "CodeGen.oz" "CodeStore.oz" "Compiler.oz" "Core.oz"
    "ForLoop.oz" "GroundZip.oz" "Lexer.oz" "Macro.oz" "NewAssembler.oz"
    "Parser.oz" "PEG.oz" "Preprocessor.oz" "PrintName.oz" "StaticAnalysis.oz"
    "Unnester.oz" "WhileLoop.oz"
    )

set(COMPILER_FUNCTORS "${MOZART_LIB_DIR}/ozbatch/Compile.oz")
foreach(FUNCTOR ${COMPILER_FUNCTORS_0})
  set(COMPILER_FUNCTORS ${COMPILER_FUNCTORS} "${MOZART_COMPILER_DIR}/${FUNCTOR}")
endforeach()

# ---------------------------------------------------------------------------- #
# Stage 0: boot-compile the functors used by the compiler                      #
# ---------------------------------------------------------------------------- #

set(STAGE_0_CACHE "${CMAKE_CURRENT_BINARY_DIR}/stage0")
set(STAGE_0_CACHE_SYSTEM "${STAGE_0_CACHE}/x-oz/system")
set(STAGE_0_BASE_OZF "${STAGE_0_CACHE}/Base.ozf")
set(STAGE_0_INIT_OZF "${STAGE_0_CACHE}/Init.ozf")
set(STAGE_0_SEARCH_LOAD "cache=${STAGE_0_CACHE}")

file(MAKE_DIRECTORY "${STAGE_0_CACHE_SYSTEM}")

find_package(Java COMPONENTS Runtime REQUIRED)

set(JAVA_OPTIONS "-Xmx1024m" CACHE STRING "Options passed to the java program")

set(BOOTCOMPILER_JAR "${MOZART_BUILD_DIR}/bootcompiler/bootcompiler.jar")
set(BOOTCOMPILER_DEFINES -D NO_GUMP)
set(BOOTCOMPILER_BASEENV_DATA_FILE "${STAGE_0_CACHE}/baseenv.txt")
set(BOOTCOMPILER_COMMAND
    ${Java_JAVA_EXECUTABLE} -jar  ${JAVA_OPTIONS} "${BOOTCOMPILER_JAR}")
set(BOOTCOMPILER_COMMON_OPTIONS
    -m "${MOZART_BUILD_DIR}/vm/vm/main/"
    ${BOOTCOMPILER_DEFINES})
set(BOOTCOMPILER_COMMON_DEPENDS
    gensources bootcompiler "${BOOTCOMPILER_JAR}")

add_custom_command(
  OUTPUT "${STAGE_0_BASE_OZF}" "${BOOTCOMPILER_BASEENV_DATA_FILE}"
  COMMAND ${BOOTCOMPILER_COMMAND} ${BOOTCOMPILER_COMMON_OPTIONS}
    --baseenv
    -o "${STAGE_0_BASE_OZF}"
    -b "${STAGE_0_CACHE}/baseenv0.txt"
    "${BASE_FUNCTOR}"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${STAGE_0_CACHE}/baseenv0.txt"
    "${BOOTCOMPILER_BASEENV_DATA_FILE}"
  DEPENDS ${BOOTCOMPILER_COMMON_DEPENDS} "${BASE_FUNCTOR}"
  COMMENT "(stage 0) ${STAGE_0_BASE_OZF}"
  VERBATIM)

set(STAGE_0_OUTPUTS "${STAGE_0_BASE_OZF}")

foreach(FUNCTOR "${RUNTIME_FUNCTOR}" "${INIT_FUNCTOR}" ${SYS_FUNCTORS} ${COMPILER_FUNCTORS})
  if("${FUNCTOR}" MATCHES "${INIT_FUNCTOR}")
    set(FUNCTOR_OZF "${STAGE_0_CACHE}/Init.ozf")
  else()
    get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
    set(FUNCTOR_OZF "${STAGE_0_CACHE_SYSTEM}/${FUNCTOR_BASENAME}.ozf")
  endif()

  set(STAGE_0_OUTPUTS ${STAGE_0_OUTPUTS} "${FUNCTOR_OZF}")

  add_custom_command(
    OUTPUT "${FUNCTOR_OZF}"
    COMMAND ${BOOTCOMPILER_COMMAND} ${BOOTCOMPILER_COMMON_OPTIONS}
      -o "${FUNCTOR_OZF}"
      -b "${BOOTCOMPILER_BASEENV_DATA_FILE}"
      "${FUNCTOR}"
    DEPENDS ${BOOTCOMPILER_COMMON_DEPENDS} "${FUNCTOR}" "${BOOTCOMPILER_BASEENV_DATA_FILE}"
    COMMENT "(stage 0) ${FUNCTOR_OZF}"
    VERBATIM)
endforeach()

add_custom_target(
  library_stage_0
  DEPENDS ${STAGE_0_OUTPUTS})

# ---------------------------------------------------------------------------- #
# Stage 1: compile Base.ozf                                                    #
# ---------------------------------------------------------------------------- #

set(STAGE_1_CACHE "${CMAKE_CURRENT_BINARY_DIR}/stage1")
set(STAGE_1_CACHE_SYSTEM "${STAGE_1_CACHE}/x-oz/system")
set(STAGE_1_BASE_OZF "${STAGE_1_CACHE}/Base.ozf")
set(STAGE_1_INIT_OZF "${STAGE_0_INIT_OZF}")
set(STAGE_1_SEARCH_LOAD "cache=${STAGE_1_CACHE}:${STAGE_0_SEARCH_LOAD}")

file(MAKE_DIRECTORY "${STAGE_1_CACHE_SYSTEM}")

add_custom_command(
  OUTPUT "${STAGE_1_BASE_OZF}"
  COMMAND ozemulator
    --base "${STAGE_0_BASE_OZF}"
    --init "${STAGE_0_INIT_OZF}"
    --search-load "${STAGE_0_SEARCH_LOAD}"
    x-oz://system/Compile.ozf
    -c "${BASE_FUNCTOR}"
    -o "${STAGE_1_BASE_OZF}"
  DEPENDS library_stage_0 "${BASE_FUNCTOR}"
  COMMENT "(stage 1) ${STAGE_1_BASE_OZF}"
  VERBATIM)

set(STAGE_1_OUTPUTS "${STAGE_1_BASE_OZF}")

add_custom_target(
  library_stage_1
  DEPENDS ${STAGE_1_OUTPUTS})
add_dependencies(library_stage_1 library_stage_0)

# ---------------------------------------------------------------------------- #
# Stage 2: compile RunTime.ozf                                                 #
# ---------------------------------------------------------------------------- #

set(STAGE_2_CACHE "${CMAKE_CURRENT_BINARY_DIR}/stage2")
set(STAGE_2_CACHE_SYSTEM "${STAGE_2_CACHE}/x-oz/system")
set(STAGE_2_BASE_OZF "${STAGE_1_BASE_OZF}")
set(STAGE_2_INIT_OZF "${STAGE_1_INIT_OZF}")
set(STAGE_2_SEARCH_LOAD "cache=${STAGE_2_CACHE}:${STAGE_1_SEARCH_LOAD}")

file(MAKE_DIRECTORY "${STAGE_2_CACHE_SYSTEM}")

set(STAGE_2_RUNTIME_OZF "${STAGE_2_CACHE_SYSTEM}/RunTime.ozf")

add_custom_command(
  OUTPUT "${STAGE_2_RUNTIME_OZF}"
  COMMAND ozemulator
    --base "${STAGE_1_BASE_OZF}"
    --init "${STAGE_1_INIT_OZF}"
    --search-load "${STAGE_1_SEARCH_LOAD}"
    x-oz://system/Compile.ozf
    -c "${RUNTIME_FUNCTOR}"
    -o "${STAGE_2_RUNTIME_OZF}"
  DEPENDS library_stage_1 "${RUNTIME_FUNCTOR}"
  COMMENT "(stage 2) ${STAGE_2_RUNTIME_OZF}"
  VERBATIM)

set(STAGE_2_OUTPUTS "${STAGE_2_RUNTIME_OZF}")

add_custom_target(
  library_stage_2
  DEPENDS ${STAGE_2_OUTPUTS})
add_dependencies(library_stage_2 library_stage_1)

# ---------------------------------------------------------------------------- #
# Stage 3: compile Init.ozf                                                    #
# ---------------------------------------------------------------------------- #

set(STAGE_3_CACHE "${CMAKE_CURRENT_BINARY_DIR}/stage3")
set(STAGE_3_CACHE_SYSTEM "${STAGE_3_CACHE}/x-oz/system")
set(STAGE_3_INIT_OZF "${STAGE_3_CACHE}/Init.ozf")
set(STAGE_3_SEARCH_LOAD "cache=${STAGE_3_CACHE}:${STAGE_2_SEARCH_LOAD}")

file(MAKE_DIRECTORY "${STAGE_3_CACHE_SYSTEM}")

add_custom_command(
  OUTPUT "${STAGE_3_INIT_OZF}"
  COMMAND ozemulator
    --base "${STAGE_2_BASE_OZF}"
    --init "${STAGE_2_INIT_OZF}"
    --search-load "${STAGE_2_SEARCH_LOAD}"
    x-oz://system/Compile.ozf
    -c "${INIT_FUNCTOR}"
    -o "${STAGE_3_INIT_OZF}"
  DEPENDS library_stage_2 "${INIT_FUNCTOR}"
  COMMENT "(stage 3) ${STAGE_3_INIT_OZF}"
  VERBATIM)

set(STAGE_3_OUTPUTS "${STAGE_3_INIT_OZF}")

add_custom_target(
  library_stage_3
  DEPENDS ${STAGE_3_OUTPUTS})
add_dependencies(library_stage_3 library_stage_2)

# ---------------------------------------------------------------------------- #
# Stage 4: compile all compiler functors with the compiler                     #
# ---------------------------------------------------------------------------- #

set(STAGE_4_CACHE "${CMAKE_CURRENT_BINARY_DIR}/stage4")
set(STAGE_4_CACHE_SYSTEM "${STAGE_4_CACHE}/x-oz/system")
set(STAGE_4_INIT_OZF "${STAGE_3_INIT_OZF}")
set(STAGE_4_SEARCH_LOAD "cache=${STAGE_4_CACHE}:${STAGE_3_SEARCH_LOAD}")

file(MAKE_DIRECTORY "${STAGE_4_CACHE_SYSTEM}")

set(STAGE_4_OUTPUTS "")

foreach(FUNCTOR ${SYS_FUNCTORS} ${COMPILER_FUNCTORS})
  get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
  set(FUNCTOR_OZF "${STAGE_4_CACHE_SYSTEM}/${FUNCTOR_BASENAME}.ozf")

  # The last buggy functor we have to exclude
  if(NOT ("${FUNCTOR_BASENAME}" MATCHES "CodeGen"))

  set(STAGE_4_OUTPUTS ${STAGE_4_OUTPUTS} "${FUNCTOR_OZF}")

  add_custom_command(
    OUTPUT "${FUNCTOR_OZF}"
    COMMAND ozemulator
      --init "${STAGE_3_INIT_OZF}"
      --search-load "${STAGE_3_SEARCH_LOAD}"
      x-oz://system/Compile.ozf
      -c "${FUNCTOR}"
      -o "${FUNCTOR_OZF}"
    DEPENDS library_stage_3 "${FUNCTOR}"
    COMMENT "(stage 4) ${FUNCTOR_OZF}"
    VERBATIM)

  endif() # NOT CodeGen.oz
endforeach()

add_custom_target(
  library_stage_4
  DEPENDS ${STAGE_4_OUTPUTS})
add_dependencies(library_stage_4 library_stage_3)

# ---------------------------------------------------------------------------- #
# Target and install                                                           #
# ---------------------------------------------------------------------------- #

set(LIBRARY_CACHE "${CMAKE_CURRENT_BINARY_DIR}/cache")
set(LIBRARY_CACHE_SYSTEM "${LIBRARY_CACHE}/x-oz/system")
set(LIBRARY_INIT_OZF "${LIBRARY_CACHE}/Init.ozf")
set(LIBRARY_SEARCH_LOAD "cache=${LIBRARY_CACHE}")

file(MAKE_DIRECTORY "${LIBRARY_CACHE_SYSTEM}")

add_custom_command(
  OUTPUT "${LIBRARY_INIT_OZF}"
  COMMAND "${CMAKE_COMMAND}" -E copy "${STAGE_4_INIT_OZF}" "${LIBRARY_INIT_OZF}"
  DEPENDS "${STAGE_4_INIT_OZF}"
  VERBATIM)

set(LIBRARY_FUNCTORS_OZF "${LIBRARY_INIT_OZF}")

foreach(FUNCTOR "${RUNTIME_FUNCTOR}" ${SYS_FUNCTORS} ${COMPILER_FUNCTORS})
  get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
  set(FUNCTOR_OZF "${LIBRARY_CACHE_SYSTEM}/${FUNCTOR_BASENAME}.ozf")
  set(LIBRARY_FUNCTORS_OZF ${LIBRARY_FUNCTORS_OZF} "${FUNCTOR_OZF}")

  foreach(STAGE_NUM 4 3 2 1 0)
    set(SRC_OZF "${STAGE_${STAGE_NUM}_CACHE_SYSTEM}/${FUNCTOR_BASENAME}.ozf")
    list(FIND "STAGE_${STAGE_NUM}_OUTPUTS" "${SRC_OZF}" INDEX)
    if(NOT (INDEX EQUAL -1))
      add_custom_command(
        OUTPUT "${FUNCTOR_OZF}"
        COMMAND "${CMAKE_COMMAND}" -E copy "${SRC_OZF}" "${FUNCTOR_OZF}"
        DEPENDS "${SRC_OZF}"
        COMMENT "Copying from stage ${STAGE_NUM}: ${FUNCTOR_OZF}"
        VERBATIM)
      break()
    endif()
  endforeach()
endforeach()

add_custom_target(
  library ALL
  DEPENDS ${LIBRARY_FUNCTORS_OZF})
add_dependencies(library library_stage_4)

# Install
install(FILES "${LIBRARY_INIT_OZF}"
        DESTINATION share/mozart/cache)
install(FILES ${LIBRARY_FUNCTORS_OZF}
        DESTINATION share/mozart/cache/x-oz/system)
