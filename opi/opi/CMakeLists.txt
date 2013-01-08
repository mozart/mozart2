# Configure paths
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(MOZART_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/../..")

set(MOZART_LIB_DIR "${MOZART_DIR}/lib/main")
set(MOZART_COMPILER_DIR "${MOZART_DIR}/lib/compiler")

find_package(Java COMPONENTS Runtime REQUIRED)

set(JAVA_OPTIONS "-Xmx1024m" CACHE STRING "Options passed to the java program")

# Configure compiler
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x ${CMAKE_CXX_FLAGS}")

if(WIN32)
  # Boost requires this
  add_definitions(-D_WIN32_WINNT=0x0501)
endif()

# Boost library

set(MOZART_BOOST_USE_STATIC_LIBS ON
    CACHE BOOL "Use the static libraries of Boost")

if(${MOZART_BOOST_USE_STATIC_LIBS})
  set(Boost_USE_STATIC_LIBS ON)
endif()

find_package(Boost COMPONENTS system thread filesystem chrono REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

if(MINGW)
  # Work around a bug in MinGW
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

# Mozart VM library

include_directories("${MOZART_DIR}/vm/vm/main" "${MOZART_BUILD_DIR}/vm/vm/main")

# Mozart VM Boost library

include_directories("${MOZART_DIR}/vm/boostenv/main"
    "${MOZART_BUILD_DIR}/vm/boostenv/main")


# Generate the .cc files using the boot compiler

set(BOOTCOMPILER_JAR "${MOZART_BUILD_DIR}/bootcompiler/bootcompiler.jar")
set(BOOTCOMPILER_DEFINES -D NO_GUMP)

set(BASE_FUNCTORS
    "${MOZART_LIB_DIR}/base/Base.oz")

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Base.ozb"
  COMMAND ${Java_JAVA_EXECUTABLE} -jar  ${JAVA_OPTIONS} "${BOOTCOMPILER_JAR}"
    --baseenv
    -o "${CMAKE_CURRENT_BINARY_DIR}/Base.ozb"
    -m "${MOZART_BUILD_DIR}/vm/vm/main/"
    -m "${MOZART_BUILD_DIR}/vm/boostenv/main/"
    -b "${CMAKE_CURRENT_BINARY_DIR}/baseenv.txt"
    ${BOOTCOMPILER_DEFINES}
    ${BASE_FUNCTORS}
  DEPENDS bootcompiler ${BASE_FUNCTORS} "${BOOTCOMPILER_JAR}"
  COMMENT "base environment"
  VERBATIM)

file(GLOB SYS_FUNCTORS
    "${MOZART_LIB_DIR}/sys/*.oz"
    "${MOZART_LIB_DIR}/support/*.oz"
    "${MOZART_LIB_DIR}/init/Init.oz"
    "${MOZART_LIB_DIR}/sp/Error.oz"
    "${MOZART_LIB_DIR}/sp/ErrorFormatters.oz"
    "${MOZART_LIB_DIR}/op/Open.oz"
    "${MOZART_LIB_DIR}/cp/Combinator.oz"
    "${MOZART_LIB_DIR}/cp/RecordC.oz"
    "${MOZART_LIB_DIR}/dp/URL.oz"
    "${MOZART_LIB_DIR}/ap/Application.oz"
    "${MOZART_DIR}/vm/boostenv/lib/*.oz")

set(COMPILER_FUNCTORS
    "Annotate.oz" "Assembler.oz" "BackquoteMacro.oz" "Builtins.oz"
    "CodeEmitter.oz" "CodeGen.oz" "CodeStore.oz" "Compiler.oz" "Core.oz"
    "ForLoop.oz" "GroundZip.oz" "Macro.oz" "PrintName.oz" "RunTime.oz"
    "StaticAnalysis.oz" "Unnester.oz" "WhileLoop.oz"
    "NewAssembler.oz" "Parser.oz" "PEG.oz")

foreach(FUNCTOR ${COMPILER_FUNCTORS})
  set(SYS_FUNCTORS ${SYS_FUNCTORS} "${MOZART_COMPILER_DIR}/${FUNCTOR}")
endforeach()

set(ALL_FUNCTORS
    "${CMAKE_CURRENT_SOURCE_DIR}/OPI.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/Emacs.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIServer.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/OPIEnv.oz"
    ${SYS_FUNCTORS})

set(ALL_OZB_FILES "${CMAKE_CURRENT_BINARY_DIR}/Base.ozb")

foreach(functor ${ALL_FUNCTORS})
  get_filename_component(basename ${functor} NAME_WE)
  set(ozbfile "${CMAKE_CURRENT_BINARY_DIR}/${basename}.ozb")

  set(ALL_OZB_FILES ${ALL_OZB_FILES} "${ozbfile}")

  add_custom_command(
    OUTPUT ${ozbfile}
    COMMAND ${Java_JAVA_EXECUTABLE} -jar  ${JAVA_OPTIONS} "${BOOTCOMPILER_JAR}"
      -o "${ozbfile}"
      -m "${MOZART_BUILD_DIR}/vm/vm/main/"
      -m "${MOZART_BUILD_DIR}/vm/boostenv/main/"
      -b "${CMAKE_CURRENT_BINARY_DIR}/baseenv.txt"
      ${BOOTCOMPILER_DEFINES}
      "${functor}"
    DEPENDS bootcompiler "${functor}"
    COMMENT "${functor}"
    VERBATIM)
endforeach()

add_custom_target(
  ozbfiles ALL
  DEPENDS ${ALL_OZB_FILES})

# Compile the executable
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  include_directories(/usr/lib/c++/v1)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

add_executable(ozengine engine.cc)
target_link_libraries(ozengine mozartvmboost mozartvm ${Boost_LIBRARIES})

if(NOT MINGW)
  target_link_libraries(ozengine pthread)
endif()

# Install
install(FILES ${ALL_OZB_FILES} DESTINATION share/mozart/boot)
install(TARGETS ozengine DESTINATION bin)
