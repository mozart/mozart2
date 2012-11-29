cmake_minimum_required(VERSION 2.8)
project(MOZART NONE)

add_subdirectory(vm)
add_subdirectory(bootcompiler)
add_subdirectory(opi)

# General CPack configuration

set(CPACK_PACKAGE_FILE_NAME "Mozart2")
set(CPACK_PACKAGE_NAME "Mozart2")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Mozart Programming System v2")
set(CPACK_PACKAGE_VERSION "2.0~alpha0")
set(CPACK_PACKAGE_VENDOR "Université catholique de Louvain")
set(CPACK_RESOURCE_FILE_LICENSE
    "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_CONTACT "Sébastien Doeraene <sjrdoeraene@gmail.com>")

# Configuration of the Bundle generator

set(MACOS_RESOURCES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/macos")

set(CPACK_BUNDLE_NAME "Mozart2")
set(CPACK_BUNDLE_PLIST "${MACOS_RESOURCES_DIR}/Info.plist")
set(CPACK_BUNDLE_STARTUP_COMMAND "${MACOS_RESOURCES_DIR}/startup")
set(CPACK_BUNDLE_ICON "${MACOS_RESOURCES_DIR}/mozart.icns")

# Configuration of the DEB generator

set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")

# Finally include CPack
include(CPack)
