# Mozart-Oz v2

[![Join the chat at https://gitter.im/mozart/mozart2](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mozart/mozart2?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

The Mozart Programming System is an open source implementation of Oz 3.
This repository contains the upcoming version 2 of the system.

The status of Mozart 2 is currently _alpha quality_. It is not ready for
production, but it can be used for experimenting, testing, and obviously, for
contributing.

# Downloads

Binary packages for Linux, Mac OS and Windows are built from time to time and
made available on
[SourceForge](http://sourceforge.net/projects/mozart-oz/files/).

Mac support is provided for 10.8.x and recent versions (2.x) of Aquamacs.

The binary distribution requires that you have installed Tcl/Tk 8.5 on your
system.

# Build Instructions

This main Readme is shamefully biased towards Linux. Side-along Readmes are
available for [Mac OS](README.MacOS.md), [Windows](README.Windows.md), and [OpenBSD](README.OpenBSD.md).

We found rather difficult to build and configure correctly CLANG/LLVM for all
supported system. Those tools are required to build pre-generated sources. In
reponse to this, we decided to include in this repository those sources. This
section describes a build with the pre-generated sources included. We do
however check the pre-generated sources at every commit, rebuilding them in a
Travis CI job. The files [.travis.yml(for Linux)](.travis.yml) and [appveyor(for
Windows)](appveyor.yml) can be very helpfull guides to build Mozart2 on your system. You can
find information about our [CI jobs](README.CI.md).

## Prerequisites

In order to build Mozart 2, you need the following tools on your computer:

*   git and Subversion to grab the source code
*   java >= 1.6.0
*   gcc >= 4.7.1 on Windows, Linux and Mac OS < 10.8;
*   cmake >= 2.8.6
*   Boost >= 1.53.0 (with development files). We recommend the use of Boost
1.65 as there is some issues with recent version of Boost with cmake.
*   Tcl/Tk 8.5 or 8.6 (with development files)
*   emacs

### Boost

As mentioned, recent versions of Boost are not currently correctly supported by
cmake. However, if you wish to build Mozart2 with a recent version of Boost(>
1.65), you should include the option `-DCMAKE_CXX_COMPILER_ARCHITECTURE_ID=your
architecture id`(x64 for a 64 bits system) in your cmake command. You may also run the cmake command to
generate Makefile twice, as the second time the cache is used to find Boost.
Should cmake fail to find your Boost you can specify the localation with the
option `-DBOOST_ROOT`.

## Clone the Mozart Repository

As the Mozart repository contains submodules, you should clone recursively:

    $ git clone --recursive https://github.com/mozart/mozart2

    You can also fetch the submodules separately using:

    $ git clone https://github.com/mozart/mozart2
    $ cd mozart2
    $ git submodule update --init

## Build Mozart

Mozart 2 is built with cmake. The following steps will perform the build:

    $ mkdir build
    $ cd build
    $ cmake -DCMAKE_BUILD_TYPE=Release ..
    $ make

You may wish to add `-j n` to the `make` command line with `n` set to the
number of CPUs to perform some of the build steps in parallel to reduce
the build time.

Once built, you may run the following to install Mozart

    $ make install

To change the directory where Mozart 2 is installed add `-DCMAKE_INSTALL_PREFIX:PATH=/path/to/install` to the `cmake` command:

    $ cmake -DCMAKE_INSTALL_PREFIX:PATH=/tmp/oz2 . && make && make install

On distros like Arch Linux and Nixos, Boost static libraries have been removed.
Please add `-DMOZART_BOOST_USE_STATIC_LIBS=OFF` to your cmake command.

# Building the pre-generated sources

You will need LLVM and Clang installed to build Mozart 2 from the git repository. Some Linux distros don't seem to ship the required LLVM/Clang cmake support files so the steps below go through building a local version of LLVM and Clang for the Mozart 2 build system to use.

The steps below assume you are in the directory above the mozart2 repository
cloned by git (refer to previous section to see how to clone the repository).

## Building LLVM and Clang

To build LLVM following the following steps:

    $ git clone --branch release_39 https://github.com/llvm-mirror/llvm
    $ cd llvm/tools
    $ git clone --branch release_39 https://github.com/llvm-mirror/clang
    $ cd ..
    $ mkdir build
    $ cd build
    $ cmake -DCMAKE_BUILD_TYPE=Release  \
            -DCMAKE_INSTALL_PREFIX:PATH=`pwd`/../../llvm-install \
            ..
    $ make
    $ make install
    $ cd ../..
    $ export PATH=`pwd`/llvm-install/bin:$PATH

You may wish to add `-j n` to the `make` command line with `n` set to the
number of CPUs to perform some of the build steps in parallel to reduce
the build time.

This will install to an `llvm-install` directory off the root directory created previously and add it to the front of the `PATH` so i t can be found in the Mozart 2 build.

## Building the pre-generated targets

You may want to move the previous pre-generated files located in
mozart2/vm/vm/main/cached and in mozart2/vm/boostenv/main/cached
to be sure they are not used in the new build.
The following steps will perform the build of the pre-generated sources:

    $ mkdir build
    $ cd build
    $ CXXFLAGS=-I`pwd`/../llvm-install/include cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX:PATH=/path/to/install \
            -DMOZART_CACHED_BUILD=OFF \
            ../mozart2
    $ make -B gensources genboostsources VERBOSE=1

The generated sources are located in build/vm/boostenv/main/generated and in
build/vm/vm/main/generated. You can check if they correspond with the previous
ones and change them accordingly. You could then proceed with the build
containing the pre-generated sources.

Alternatively, you can complete the build by running the following :

    $ make
    $ make install

Change `/path/to/install` to the location where Mozart 2 should be installed.

On distros like Arch Linux and Nixos, Boost static libraries have been removed.
Please add `-DMOZART_BOOST_USE_STATIC_LIBS=OFF` to your cmake command.

# CMake Options

Other cmake options can be given with the form `-DOPTION=Value`. The table below
lists the options you can add.

<table>
  <thead>
    <tr><th>Option</th><th>Value</th><th>Required if</th>
  </thead>
  <tbody>
    <tr>
      <td>CMAKE_BUILD_TYPE</td>
      <td>Debug or Release</td>
      <td>Always</td>
    </tr>
    <tr>
      <td>CMAKE_INSTALL_PREFIX</td>
      <td>Where `make install` should install</td>
      <td>-</td>
    </tr>
    <tr>
      <td>CMAKE_CXX_COMPILER</td>
      <td>Path to your C++ compiler</td>
      <td>Mac OS: must be forced to clang++</td>
    </tr>
    <tr>
      <td>CMAKE_MAKE_PROGRAM</td>
      <td>Path to your make program</td>
      <td>Windows: must be forced to MinGW make</td>
    </tr>
    <tr>
      <td>GTEST_SRC_DIR and GTEST_BUILD_DIR</td>
      <td>Paths to the source and build directories of GTest</td>
      <td>If not present, GTest will be downloaded and built automatically</td>
    </tr>
    <tr>
      <td>LLVM_SRC_DIR and LLVM_BUILD_DIR</td>
      <td>Paths to the source and build directories of LLVM</td>
      <td>If not present, LLVM will be downloaded and built automatically</td>
    </tr>
    <tr>
      <td>CLANG_SRC_DIR</td>
      <td>Paths to the source directory of CLANG</td>
      <td>Use this if cmake cannot find the CLANG sources</td>
    </tr>
    <tr>
      <td>EMACS</td>
      <td>Path to the Emacs executable</td>
      <td>Required on Windows (on Unix it can be found automatically, in principle)</td>
    </tr>
    <tr>
      <td>CPACK_GENERATOR</td>
      <td>Comma-separated list of generators for CPack</td>
      <td>Optional, see CPack documentation</td>
    </tr>
    <tr>
      <td>BOOST_ROOT</td>
      <td>Path to the boost root</td>
      <td>May be used if cmake fails to find boost</td>
    </tr>
    <tr>
      <td>CMAKE_CXX_COMPILER_ARCHITECTURE_ID</td>
      <td>Indicates in which architecture the system is compiled</td>
      <td>Required with recent version of Boost (due to some incompability with cmake)</td>
    </tr>
  </tbody>
</table>

There is a NixOS expression to install the Mozart2 binary:
`nix-env -i mozart-binary`
