cmake_minimum_required(VERSION 2.8.6)
project(MOZARTWISH)

find_package(TCL REQUIRED)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_INTERP_RESULT=1")


if(WIN32)
  # Path and version for Inno Setup
  set(ISS_TCL_VERSION ${TCLSH_VERSION_STRING} CACHE STRING "Tcl version string")
  set(ISS_TCL_EXEC ${TCL_TCLSH} CACHE STRING "Tclsh executable path")
  link_directories("/c/msys64/mingw64/bin" "/c/msys64/mingw64/lib")

  set(TCL_FOUND TRUE)
  set(TK_FOUND TRUE)
  set(TCLTK_FOUND TRUE)
  set(TCL_LIBRARY "C:/tcltk/lib/libtcl86.a")
  set(TCL_INCLUDE_PATH "C:/tcltk/include")
  set(TCL_TCLSH "C:/tclsh/bin/tclsh86.exe")
  set(TK_LIBRARY "C:/tcltk/lib/libtk86.a")
  set(TK_INCLUDE_PATH "C:/tcltk/include")
  set(TK_WISH "C:/tcltk/bin/wish86.exe")

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
