if("${GTEST_SRC_DIR}" STREQUAL "${DEFAULT_GTEST_SRC_DIR}")
  ExternalProject_Add(gtest
    SVN_REPOSITORY http://googletest.googlecode.com/svn/trunk
    CMAKE_ARGS -DCMAKE_BUILD_TYPE:STRING=Debug
    INSTALL_COMMAND ""
    TEST_COMMAND ""
    )
endif()
add_subdirectory(src)
add_subdirectory(test)
