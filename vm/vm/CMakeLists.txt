if("${GTEST_SRC_DIR}" STREQUAL "${DEFAULT_GTEST_SRC_DIR}" AND
   NOT EXISTS "${GTEST_BUILD_DIR}/libgtest.a")

  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(GTEST_CMAKE_EXTRA_ARGS "-DCMAKE_CXX_FLAGS=-stdlib=libc++")
  endif()

  separate_arguments(GTEST_CMAKE_ARGS UNIX_COMMAND
    "-DCMAKE_BUILD_TYPE=Debug
     -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
     -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
     -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
     ${GTEST_CMAKE_EXTRA_ARGS}"
  )

  ExternalProject_Add(gtest
    SVN_REPOSITORY http://googletest.googlecode.com/svn/trunk
    CMAKE_ARGS ${GTEST_CMAKE_ARGS}
    INSTALL_COMMAND ""
    TEST_COMMAND ""
    )
endif()
add_subdirectory(main)
add_subdirectory(test)
