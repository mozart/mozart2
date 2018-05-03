cmake_minimum_required(VERSION 2.8.6)
project(MOZARTWISH)

if(NOT TCLTK_ROOT)
  find_package(TCL REQUIRED)
else()
  set(TCL_FOUND TRUE)
  set(TK_FOUND TRUE)
  set(TCLTK_FOUND TRUE)
  set(TCLSH_VERSION_STRING 8.6)
  set(TCL_LIBRARY "${TCLTK_ROOT}/lib/libtcl86.a")
  set(TCL_INCLUDE_PATH "${TCLTK_ROOT}/include")
  set(TCL_TCLSH "${TCLTK_ROOT}/bin/tclsh86.exe")
  set(TK_LIBRARY "${TCLTK_ROOT}/lib/libtk86.a")
  set(TK_INCLUDE_PATH "${TCLTK_ROOT}/include")
  set(TK_WISH "${TCLTK_ROOT}/bin/wish86.exe")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_INTERP_RESULT=1")

if(WIN32)
  # Path and version for Inno Setup
  set(ISS_TCL_VERSION ${TCLSH_VERSION_STRING} CACHE STRING "Tcl version string")
  set(ISS_TCL_EXEC ${TCL_TCLSH} CACHE STRING "Tclsh executable path")

  set(MAIN_SRC winmain.cc)
else()
  set(MAIN_SRC unixmain.cc)
endif()

include_directories("${TCL_INCLUDE_PATH}" "${TK_INCLUDE_PATH}")

add_executable(ozwish ${MAIN_SRC})
target_link_libraries(ozwish "${TCL_LIBRARY}" "${TK_LIBRARY}")

if(NOT MINGW)
  target_link_libraries(ozwish pthread)
endif()

# Install
install(TARGETS ozwish DESTINATION bin)
