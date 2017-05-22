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

## Prerequisites

In order to build Mozart 2, you need the following tools on your computer:

*   git and Subversion to grab the source code
*   java >= 1.6.0
*   gcc >= 4.7.1 on Windows, Linux and Mac OS < 10.8;
    or clang >= 3.1 on Mac OS >= 10.8
*   cmake >= 2.8.6
*   Boost >= 1.53.0 (with development files)
*   Tcl/Tk 8.5 or 8.6 (with development files)
*   emacs

For building CLANG/LLVM:
*   LibXML2-dev (tested with version 2.9.3)
*   OCaml-findlib
*   libCTypes-OCaml-dev (>= 0.4 - available in Debian Unstable as of Jan. 2016)

On Linux, use your favorite package manager to grab these tools. Refer to the
specialized Readmes for recommendations on Mac OS and Windows.

## Pre-generated source tree

The release source snapshots contain pre-generated C++ code that allows you
to build without requiring LLVM or Clang. This is the easiest way to build
a version of Mozart 2 from source. The latest pre-generated source snapshot
is [mozart2-2.0.0-beta.0-Source.zip](https://github.com/layus/mozart2/releases/download/v2.0.0-beta.0/mozart2-2.0.0-beta.0-Source.zip).

To build from the snapshot:

    $ wget https://github.com/layus/mozart2/releases/download/v2.0.0-beta.0/mozart2-2.0.0-beta.0-Source.zip
    $ unzip mozart2-2.0.0-beta.0-Source.zip
    $ cd mozart2-2.0.0-beta.0-Source/
    $ cmake .
    $ make
    $ make install

To change the directory where Mozart 2 is installed add `-DCMAKE_INSTALL_PREFIX:PATH=/path/to/install` to the `cmake` command:

    $ cmake -DCMAKE_INSTALL_PREFIX:PATH=/tmp/oz2 . && make && make install

If you want to work on developing Mozart 2 itself you'll probably want to regenerate the C++ headers interfacing to Oz objects at some point. In that case you should use the build instructions below.

# Git Build instructions

You will need LLVM and Clang installed to build Mozart 2 from the git repository. Some Linux distros don't seem to ship the required LLVM/Clang cmake support files so the steps below go through building a local version of LLVM and Clang for the Mozart 2 build system to use. The steps below assume you are in an empty directory to build LLVM, Clang and Mozart 2:

    $ mkdir oz2
    $ cd oz2

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
    
## Clone the Mozart repository

As the Mozart repository contains submodules, you should clone recursively:

    $ git clone --recursive https://github.com/mozart/mozart2

    You can also fetch the submodules separately using:

    $ git clone https://github.com/mozart/mozart2
    $ cd mozart2
    $ git submodule update --init
    $ cd ..

## Build Mozart

Mozart 2 is built with cmake. The following steps will perform the build:

    $ mkdir build
    $ cd build
    $ CXXFLAGS=-I`pwd`/llvm-install/include cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX:PATH=/path/to/install \
            ../mozart2
    $ make
    $ make install

You may wish to add `-j n` to the `make` command line with `n` set to the
number of CPUs to perform some of the build steps in parallel to reduce
the build time.

Change `/path/to/install` to the location where Mozart 2 should be installed.

On distros like Arch Linux and Nixos, Boost static libraries have been removed.
Please add `-DMOZART_BOOST_USE_STATIC_LIBS=OFF` to your cmake command.

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
  </tbody>
</table>

There is a NixOS expression to install the Mozart2 binary:
`nix-env -i mozart-binary`
