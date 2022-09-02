cmake_minimum_required(VERSION 2.6)
project(MOZARTBOOTCOMPILER NONE)

find_package(Java COMPONENTS Runtime REQUIRED)

set(SBT_JAVA_OPTS
    -Xms512M -Xmx1024M -Xss1M
    CACHE STRING "Options passed to the Java executable when running sbt")

set(SBT "${Java_JAVA_EXECUTABLE}" ${SBT_JAVA_OPTS} -Dfile.encoding=UTF-8
  -jar "${CMAKE_CURRENT_SOURCE_DIR}/sbt-launch.jar")

file(GLOB_RECURSE bootcompiler_sources src/*)
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/bootcompiler.jar"
  COMMAND ${SBT} assembly
  COMMAND ${CMAKE_COMMAND} -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/target/scala-2.13/bootcompiler-assembly-2.0-SNAPSHOT.jar"
    "${CMAKE_CURRENT_BINARY_DIR}/bootcompiler.jar"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS "sbt-launch.jar" "build.sbt" "project/plugins.sbt" ${bootcompiler_sources}
  COMMENT "Building the bootcompiler"
  VERBATIM)

add_custom_target(bootcompiler DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/bootcompiler.jar")
