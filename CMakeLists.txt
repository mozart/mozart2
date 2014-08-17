cmake_minimum_required(VERSION 2.8)
project(MOZART CXX)

ENABLE_TESTING()
# Custom CMake modules

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_local ${CMAKE_MODULE_PATH})
include(MozartProperties)

# Set variables that the submodules will need to find me
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(MOZART_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}")

# Some helpers when using MinGW
if(MINGW)
  get_filename_component(CMAKE_MAKE_PROGRAM_PATH "${CMAKE_MAKE_PROGRAM}" PATH)
  get_filename_component(CMAKE_MAKE_PROGRAM_PATH_PARENT "${CMAKE_MAKE_PROGRAM_PATH}" PATH)

  set(MINGW_ROOT "${CMAKE_MAKE_PROGRAM_PATH_PARENT}"
      CACHE PATH "Path where MinGW is installed")
  set(MINGW_COMPILER_VERSION "4.9.1"
      CACHE STRING "Version of GCC in your MinGW installation")

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-format -Wno-format-extra-args")
  set(CMAKE_CXX_STANDARD_LIBRARIES "-static -lwsock32 -lws2_32 ${CMAKE_CSS_STANDARD_LIBRARIES}")
  
  # Check for gcc target architecture
  execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpmachine OUTPUT_VARIABLE GCC_ARCH)
  string(STRIP "${GCC_ARCH}" GCC_ARCH_TRIPLE)
  message(STATUS "Target architecture : ${GCC_ARCH_TRIPLE}")

  set(DEFAULT_MOZART_GENERATOR_FLAGS
        "-I${MINGW_ROOT}/${GCC_ARCH_TRIPLE}/include/c++"
        "-I${MINGW_ROOT}/${GCC_ARCH_TRIPLE}/include/c++/${GCC_ARCH_TRIPLE}"
        "-I${MINGW_ROOT}/${GCC_ARCH_TRIPLE}/include")  
  
  set(BOOST_ROOT "${MINGW_ROOT}"
      CACHE PATH "Path where Boost is installed")

  # Configuration for resources files
    set(CMAKE_RC_COMPILER_INIT windres)
      enable_language(RC)
        set(CMAKE_RC_COMPILE_OBJECT
	    "<CMAKE_RC_COMPILER> <FLAGS> -O coff <DEFINES> -i <SOURCE> -o <OBJECT>")
else()
  set(DEFAULT_MOZART_GENERATOR_FLAGS "")
endif()

# Some configuration

if(WIN32)
  add_definitions(-DMOZART_WINDOWS=1)
  set(DEFAULT_MOZART_GENERATOR_FLAGS "-DMOZART_WINDOWS=1" ${DEFAULT_MOZART_GENERATOR_FLAGS})
endif()

# The subdirectories which contain the real thing

add_subdirectory(vm)
add_subdirectory(bootcompiler)
add_subdirectory(boosthost)
add_subdirectory(lib)
add_subdirectory(opi)
add_subdirectory(wish)
add_subdirectory(stdlib)
add_subdirectory(platform-test)

# Add launcher and icons
if(UNIX)
  install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/distrib/share/" DESTINATION share)
endif()

# General CPack configuration

string(TOLOWER "${CMAKE_SYSTEM_NAME}" MOZART_SYSTEM_NAME)

set(CPACK_PACKAGE_FILE_NAME
    "mozart2-${MOZART_PROP_OZ_VERSION}-${MOZART_PROP_PLATFORM_ARCH}-${MOZART_SYSTEM_NAME}")
set(CPACK_PACKAGE_NAME "mozart2")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Mozart Programming System v2")
set(CPACK_PACKAGE_VERSION "${MOZART_PROP_OZ_VERSION}")
set(CPACK_PACKAGE_VENDOR "Université catholique de Louvain")
set(CPACK_RESOURCE_FILE_LICENSE
    "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.txt")
set(CPACK_PACKAGE_CONTACT "Sébastien Doeraene <sjrdoeraene@gmail.com>")

# Configuration of the Bundle generator

set(MACOS_RESOURCES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/macos")

set(CPACK_BUNDLE_NAME "Mozart2")
set(CPACK_BUNDLE_PLIST "${MACOS_RESOURCES_DIR}/Info.plist")
set(CPACK_BUNDLE_STARTUP_COMMAND "${MACOS_RESOURCES_DIR}/startup")
set(CPACK_BUNDLE_ICON "${MACOS_RESOURCES_DIR}/mozart.icns")

# Configuration of the DEB generator

if(${MOZART_PROP_PLATFORM_ARCH} MATCHES "x86_64")
  set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
else()
  set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "${MOZART_PROP_PLATFORM_ARCH}")
endif()
string(REGEX REPLACE "-(alpha|beta|rc)\\." "~\\1"
       CPACK_DEBIAN_PACKAGE_VERSION "${MOZART_PROP_OZ_VERSION}")
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "tcl8.5, tk8.5, emacs")

# Configuration of the RPM generator

set(CPACK_RPM_PACKAGE_ARCHITECTURE "${MOZART_PROP_PLATFORM_ARCH}")
set(CPACK_RPM_PACKAGE_REQUIRES "tcl >= 8.5, tk >= 8.5, emacs")
set(CPACK_RPM_PACKAGE_GROUP "Development/Languages")

# Finally include CPack
include(CPack)
