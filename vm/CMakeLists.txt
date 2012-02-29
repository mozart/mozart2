if("${GTEST_SRC_DIR}" STREQUAL "${DEFAULT_GTEST_SRC_DIR}" AND
   NOT EXISTS "${GTEST_BUILD_DIR}/libgtest.a")
  ExternalProject_Add(gtest
    SVN_REPOSITORY http://googletest.googlecode.com/svn/trunk
    CMAKE_ARGS -DCMAKE_BUILD_TYPE:STRING=Debug
    INSTALL_COMMAND ""
    TEST_COMMAND ""
    )
endif()
add_subdirectory(main)
add_subdirectory(test)
