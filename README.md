# Mozart-Oz v2

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



# Build instructions

This main Readme is shamefully biased towards Linux. Side-along Readmes are
available [for Mac OS](README.MacOS.md) and [for Windows](README.Windows.md).

## Requirements

In order to build Mozart 2, you need the following tools on your computer:

*   git and Subversion to grab the source code
*   java >= 1.6.0
*   gcc >= 4.7.1 on Windows, Linux and Mac OS < 10.8;
    or clang >= 3.1 on Mac OS >= 10.8
*   cmake >= 2.8.6
*   Boost >= 1.49.0 (with development files)
*   Tcl/Tk 8.5 or 8.6 (with development files)
*   emacs

On Linux, use your favorite package manager to grab these tools. Refer to the
specialized Readmes for recommendations on Mac OS and Windows.

## Suggested directory layout

We suggest that you use the following directory layout, starting from a
directory `<projects>` where you store your projects:

```
<projects>
  + mozart2              // cloned from this repo
  + externals
      + gtest            // source of GTest (see below)
      + llvm             // source of LLVM (see below)
  + builds               // root for your builds
      + gtest-debug      // debug build of GTest
      + llvm-release     // release build of LLVM
      + mozart2-debug    // debug build of Mozart
      + mozart2-release  // release build of Mozart
```

Throughout the following instructions, we will assume this layout.

## Obtaining GTest and LLVM

Mozart2 uses GTest and LLVM as subprojects, which you have to download and
build prior to building Mozart 2.

**Not recommended.** If you do not want to mess with these, you can choose to skip
this section, and let the automatic build process fetch them and build them for
you. Use this "feature" at your own risk, because none of us tests this
anymore, and we may decide to remove support for it at some point.

First download all the sources. Both projects use Subversion.

```
projects$ cd externals
externals$ svn co http://googletest.googlecode.com/svn/trunk gtest
[...]
externals$ svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_33/final llvm
[...]
externals$ cd llvm/tools/
tools$ svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_33/final clang
[...]
tools$ cd ../../..
projects$
```

Next, build the projects. Except on Windows (where parallel make does not
work, it seems), we suggest you use the `-jN` option of `make`, specifying
how many tasks make can run in parallel. Building LLVM is quite long, and this
can significantly speed up the process.

```
projects$ cd builds
builds$ mkdir gtest-debug
builds$ cd gtest-debug
gtest-debug$ cmake -DCMAKE_BUILD_TYPE=Debug ../../externals/gtest
[...]
gtest-debug$ make # (optionally with -jN for a given N)
[...]
gtest-debug$ cd ..
builds$ mkdir llvm-release
builds$ cd llvm-release
llvm-release$ cmake -DCMAKE_BUILD_TYPE=Release ../../externals/llvm
[...]
llvm-release$ make # (optionally with -jN for a given N)
[...]
llvm-release$
```

## Clone the Mozart repository

As the Mozart repository contains submodules, you should clone recursively:

```
projects$ git clone --recursive git://github.com/mozart/mozart2.git
```

You can also fetch the submodules separately using:

```
mozart2$ git submodule update --init
```

## Build Mozart

The build process of Mozart is ruled by cmake. You must first configure your
build environment:

```
builds$ mkdir mozart2-release
builds$ cd mozart2-release
mozart2-release$ cmake -DCMAKE_BUILD_TYPE=Release [OtherOptions...] ../../mozart2
```
On distros like Arch Linux and Nixos, Boost static libraries have been removed.
Please add `-DMOZART_BOOST_USE_STATIC_LIBS=OFF` to your cmake command.

Here is a complete Nixos example cmake command to build Mozart2:
`cmake -DCMAKE_BUILD_TYPE=Release -DGTEST_SRC_DIR=../../externals/gtest -DGTEST_BUILD_DIR=../gtest-debug -DLLVM_SRC_DIR=~/.nix-profile/include/llvm -DLLVM_BUILD_DIR=~/.nix-profile/ -DCLANG_BUILD_DIR=~/.nix-profile/include -DCLANG_SRC_DIR=~/.nix-profile/ -DMOZART_BOOST_USE_STATIC_LIBS=OFF -DBOOST_INCLUDEDIR=~/.nix-profile/include -DBOOST_LIBRARYDIR=~/.nix-profile/lib -DMOZART_GENERATOR_FLAGS="-I/home/stewart/.nix-profile/include/c++/4.7.3;-I/home/stewart/.nix-profile/include/c++/4.7.3/x86_64-unknown-linux-gnu;-I/home/stewart/.nix-profile/include" -DCMAKE_INSTALL_PREFIX=~/oz ../../mozart2`

The options must be given with the form `-DOPTION=Value`. The table below
lists the options you need.

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

To effectively build Mozart, use `make`.

The same recommandation about using `-jN` holds. Building Mozart 2 is _very_
long (especially when done from scratch). But beware, each task can be very
demanding in terms of RAM. If you run out of RAM, decrease N.

```
mozart2-release$ make # (optionally with -jN for a given N)
```

Of course you can install with

```
mozart2-release$ make install
```
