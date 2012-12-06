cmake_minimum_required(VERSION 2.8.6)
project(MOZARTWISH)

find_package(TCL REQUIRED)

include_directories("${TCL_INCLUDE_PATH}" "${TK_INCLUDE_PATH}")
