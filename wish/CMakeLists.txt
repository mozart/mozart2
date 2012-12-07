cmake_minimum_required(VERSION 2.8.6)
project(MOZARTWISH)

find_package(TCL REQUIRED)

include_directories("${TCL_INCLUDE_PATH}" "${TK_INCLUDE_PATH}")

if(WIN32)
  set(MAIN_SRC winmain.cc)
else()
  set(MAIN_SRC unixmain.cc)
endif()

add_executable(ozwish ${MAIN_SRC})
target_link_libraries(ozwish "${TCL_LIBRARY}" "${TK_LIBRARY}")

if(NOT MINGW)
  target_link_libraries(ozwish pthread)
endif()

# Install
install(TARGETS ozwish DESTINATION bin)
