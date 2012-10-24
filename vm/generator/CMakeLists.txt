if("${LLVM_SRC_DIR}" STREQUAL "${DEFAULT_LLVM_SRC_DIR}" AND
   NOT EXISTS "${LLVM_BUILD_DIR}/bin/clang++")

  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(LLVM_CMAKE_EXTRA_ARGS "-DCMAKE_CXX_FLAGS=-stdlib=libc++")
  endif()

  separate_arguments(LLVM_CMAKE_ARGS UNIX_COMMAND
    "-DCMAKE_BUILD_TYPE=Release
     -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
     -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
     -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
     ${LLVM_CMAKE_EXTRA_ARGS}"
  )

  ExternalProject_Add(llvm
    SVN_REPOSITORY http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_31/final
    CMAKE_ARGS ${LLVM_CMAKE_ARGS}
    INSTALL_COMMAND ""
    TEST_COMMAND ""
    )
  ExternalProject_Add_Step(llvm download_clang
    COMMAND svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_31/final ${ep_base}/Source/llvm/tools/clang
    DEPENDEES download
    DEPENDERS update
    )
  ExternalProject_Add_Step(llvm update_clang
    COMMAND svn update ${ep_base}/Source/llvm/tools/clang
    DEPENDEES update
    DEPENDERS build
    )
endif()
add_subdirectory(main)
