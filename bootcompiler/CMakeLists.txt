cmake_minimum_required(VERSION 2.6)
project(MOZARTBOOTCOMPILER NONE)

find_package(Java COMPONENTS Runtime REQUIRED)

set(SBT_JAVA_OPTS
    -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=384M
    CACHE STRING "Options passed to the Java executable when running sbt")

set(SBT "${Java_JAVA_EXECUTABLE}" ${SBT_JAVA_OPTS} -Dfile.encoding=UTF-8
  -jar "${CMAKE_CURRENT_SOURCE_DIR}/sbt-launch.jar")

add_custom_target(bootcompiler
  ALL
  COMMAND ${SBT} one-jar
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_SOURCE_DIR}/target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar"
    "${CMAKE_CURRENT_BINARY_DIR}/bootcompiler.jar"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT "Building the bootcompiler"
  VERBATIM)
