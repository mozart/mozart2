# Windows-specific notes

General information can be found in the [main Readme](README.md). Unless
othewise specified here, instructions found in the main Readme apply.

## Required software

Download and install the following tools:

*   TortoiseSVN and TortoiseGit
*   The [MinGW distro](http://nuwen.net/mingw.html) of nuwen.net,
    which includes a C++11 enabled GCC and Boost
*   CMake >= 2.8.6
*   Emacs
*   [Active TCL](http://www.activestate.com/activetcl/downloads)
    _32 bits_ (even if you are running a 64-bit Windows), preferably v8.5

We will refer to the installation directories of MinGW, CMake and Emacs by
`<mingw>`, `<cmake>` and `<emacs>`, respectively.

Also, each time we mention "4.7.2", we are referring to the version of GCC
that accompanies MinGW. Make sure to adapt this to your version.

## Global configuration

Put the following directories in your PATH:

*    `<mingw>\bin`
*    `<cmake>\bin`
*    `<emacs>\bin`
*    `<projects>\builds\llvm-release\bin`

Patch the file `<mingw>\include\c++\4.7.2\i686-pc-mingw32\bits\c++config.h` by
replacing

    /* Define if __float128 is supported on this host. */
    #define _GLIBCXX_USE_FLOAT128 1

by

    /* Define if __float128 is supported on this host. */
    #ifndef __clang__
    #define _GLIBCXX_USE_FLOAT128 1
    #endif

## GTest and LLVM

Download them as specified in the main Readme.

Configure and build GTest:

    gtest-debug>cmake -G "MinGW Makefiles" -DCMAKE_MAKE_PROGRAM=<mingw>/bin/make.exe -DCMAKE_BUILD_TYPE=Debug ../../externals/gtest
    gtest-debug>make

Configure and build LLVM with:

    llvm-release>cmake -G "MinGW Makefiles" -DCMAKE_MAKE_PROGRAM=<mingw>/bin/make.exe -DCMAKE_BUILD_TYPE=Release ../../externals/llvm
    llvm-release>make

## Configuration and build of Mozart2

The "build" version (not "installed") of Mozart2 is very tedious to run on
Windows. We suggest that you always `make install` (we do that ourselves).
You can use the configuration option `-DCMAKE_INSTALL_PREFIX=C:/Where/You/Want`
of CMake to specify in which directory you want it to be installed.

Configure and build Mozart with the following incantation. It might be
necessary to open your command prompt with administrator privileges.

    mozart2-release>cmake -G "MinGW Makefiles" -DCMAKE_MAKE_PROGRAM=<mingw>/bin/make.exe -DCMAKE_BUILD_TYPE=Release -DGTEST_SRC_DIR=../../externals/gtest -DGTEST_BUILD_DIR=../gtest-debug -DLLVM_SRC_DIR=../../externals/llvm -DLLVM_BUILD_DIR=../llvm-release ../../mozart2
    mozart2-release>make
    mozart2-release>make install

If the script does not detect correctly where MinGW is installed, you can tell
it using the option `-DMINGW_ROOT=<mingw>`. Similarly, if the version of GCC in
your MinGW is not 4.7.2, you can tell it with
`-DMINGW_COMPILER_VERSION=4.7.1`, e.g.
