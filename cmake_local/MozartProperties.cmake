find_package(Git)

include(TargetArch)

# platform.os

if(WIN32)
  set(MOZART_PROP_PLATFORM_OS "win32")
else()
  string(TOLOWER "${CMAKE_SYSTEM_NAME}" MOZART_PROP_PLATFORM_OS)
endif()

# platform.arch

target_architecture(MOZART_PROP_PLATFORM_ARCH)

# oz.version

execute_process(
  COMMAND ${GIT_EXECUTABLE} describe --dirty
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  OUTPUT_VARIABLE git_describe_output
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)

if("${git_describe_output}" MATCHES "^v[0-9].+-[0-9]+-g[0-9a-f]+(-dirty)?$")
  string(REGEX REPLACE "^v(.+)-([0-9]+)-g([0-9a-f]+)((-dirty)?)$" "\\1+build.\\2.\\3\\4"
         MOZART_PROP_OZ_VERSION "${git_describe_output}")
elseif("${git_describe_output}" MATCHES "^v[0-9].+[0-9](-dirty)?$")
  string(REGEX REPLACE "^v(.+)$" "\\1"
         MOZART_PROP_OZ_VERSION "${git_describe_output}")
else()
  message(WARNING "'git describe --dirty' did not return something sensible")
  set(MOZART_PROP_OZ_VERSION "unknown")
endif()

unset(git_describe_output)

# oz.date

execute_process(
  COMMAND ${GIT_EXECUTABLE} log "--format=%aD" -1
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  OUTPUT_VARIABLE git_date_output
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)

set(MOZART_PROP_OZ_DATE "${git_date_output}")

unset(git_date_output)

# Display which version we found

message(STATUS "Mozart ${MOZART_PROP_OZ_VERSION} (${MOZART_PROP_OZ_DATE})")
