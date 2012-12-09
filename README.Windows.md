# Setup a build environment on Windows

## Required software

Download and install the following tools:

*   TortoiseSVN and TortoiseGit.
*   The [MinGW distro](http://nuwen.net/mingw.html) of nuwen.net.
*   CMake.
*   Emacs.

Checkout GTest as explained in the main Readme. For LLVM, use version 3.2,
which is in RC3 as of this writing.

We will assume that MinGW is installed in the directory `C:\MinGW`. This is
not a requirement. Just make sure to adapt the paths that we give in this
readme.

## Global configuration

Put the following directories in your PATH:

*    `C:\MinGW\bin`
*    `<cmake>\bin`
*    `<emacs>\bin`
*    `<projects>\builds\llvm-release\bin`

Patch the file C:\MinGW\include\c++\4.7.2\i686-pc-mingw32\bits\c++config.h by
replacing

    /* Define if __float128 is supported on this host. */
    #define _GLIBCXX_USE_FLOAT128 1

by

    /* Define if __float128 is supported on this host. */
    #ifndef __clang__
    #define _GLIBCXX_USE_FLOAT128 1
    #endif

## Configuration and build of GTest and LLVM

Configure and build GTest:

    gtest-debug>cmake -G "MinGW Makefiles"
        -DCMAKE_MAKE_PROGRAM=C:/MinGW/bin/make.exe -DCMAKE_BUILD_TYPE=Debug
        ../../externals/gtest
    gtest-debug>make

Configure and build LLVM with:

    llvm-release>cmake -G "MinGW Makefiles"
        -DCMAKE_MAKE_PROGRAM=C:/MinGW/bin/make.exe -DCMAKE_BUILD_TYPE=Release
        ../../externals/llvm
    llvm-release>make

## Configuration and build of Mozart2

Configure and build Mozart with:

    mozart2-release>cmake -G "MinGW Makefiles"
        -DCMAKE_MAKE_PROGRAM=C:/MinGW/bin/make.exe -DCMAKE_BUILD_TYPE=Release
        -DGTEST_SRC_DIR=../../externals/gtest -DGTEST_BUILD_DIR=../gtest-debug
        -DLLVM_SRC_DIR=../../externals/llvm -DLLVM_BUILD_DIR=../llvm-release
        ../../mozart2
    mozart2-release>make

If the script does not detect correctly where MinGW is installed, you can tell
it using the option `-DMINGW_ROOT=C:/Path/To/MinGW`. Similarly, if the version of GCC in your
MinGW is not 4.7.2, you can tell with `-DMINGW_COMPILER_VERSION=4.7.1`.
