if("${LLVM_SRC_DIR}" STREQUAL "${DEFAULT_LLVM_SRC_DIR}")
  ExternalProject_Add(llvm
    SVN_REPOSITORY http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_30/final
    CMAKE_ARGS -DCMAKE_BUILD_TYPE:STRING=Release
    INSTALL_COMMAND ""
    TEST_COMMAND ""
    )
  ExternalProject_Add_Step(llvm download_clang
    COMMAND svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_30/final ${ep_base}/Source/llvm/tools/clang
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
