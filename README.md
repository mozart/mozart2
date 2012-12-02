# Mozart-Oz v2

The Mozart Programming System is an open source implementation of Oz 3.
This repository contains the upcoming version 2 of the system.
The [Website](http://www.mozart-oz.org/) currently refers to the last stable
version, which is 1.4.0.

This is a meta-repository that aggregates all the repositories of Mozart as
submodules:

* [Virtual Machine](https://github.com/mozart/mozart2-vm)
* [Bootcompiler](https://github.com/mozart/mozart2-bootcompiler)
* [Standard library](https://github.com/mozart/mozart2-library)
* [Compiler](https://github.com/mozart/mozart2-compiler)
* [OPI](https://github.com/mozart/mozart2-opi)

The purpose of this meta-repository is to link together commits of these
subprojects that are globally coherent, and provide a unified, automated build
process.

# Downloads

The [Downloads](https://github.com/mozart/mozart2/downloads) page on GitHub
features binary packages of the current state of development of Mozart 2.

These downloads must be considered as having _alpha quality_. They are
certainly not ready for production, and only remotely ready for experimentation.

# Build instructions

## Requirements

In order to build Mozart 2, you need the following tools on your computer:

*   git and Subversion to grab the source code
*   java >= 1.6.0
*   gcc >= 4.7.1 on Windows and Linux; or clang >= 3.1 on Mac OS
*   cmake >= 2.8.6
*   development version of Boost >= 1.49.0
*   emacs

On Linux and Mac OS, use your favorite package manager to grab these tools.

On Windows, we recommend that you use the
[MinGW distro](http://nuwen.net/mingw.html) of nuwen.net, which is enabled
for C++11 and Boost.

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

Mozart2 uses GTest and LLVM as subprojects. If you do not want to mess with
these, you can choose to skip this section, and let the automatic build
process fetch them and build them for you.

However, if you intend to have at least 2 builds of Mozart (which is likely:
the debug build and the release build), it is better to compile them yourself
once, and then use this only installation in all your builds of Mozart.

To build yourself, simply follow the steps below.

First download all the sources. Both projects use Subversion. If you use
Windows, use the trunk version of LLVM instead.

```
projects$ cd externals
externals$ svn co http://googletest.googlecode.com/svn gtest
[...]
externals$ svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_31/final llvm
[...]
externals$ cd llvm/tools/
tools$ svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_31/final clang
[...]
tools$ cd ../../..
projects$
```

Next, build the projects:

```
projects$ cd builds
builds$ mkdir gtest-debug
builds$ cd gtest-debug
gtest-debug$ cmake -DCMAKE_BUILD_TYPE=Debug ../../externals/gtest
[...]
gtest-debug$ make -j7 # adapt to your number of CPUs
[...]
gtest-debug$ cd ..
builds$ mkdir llvm-release
builds$ cd llvm-release
llvm-release$ cmake -DCMAKE_BUILD_TYPE=Release ../../externals/llvm
[...]
llvm-release$ make -j7
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
builds$ mkdir mozart2-debug
builds$ cd mozart2-debug
mozart2-debug$ cmake -DCMAKE_BUILD_TYPE=Debug [OtherOptions...] ../../mozart2
```

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

To effectively build Mozart, use `make`:

```
mozart2-debug$ make -j7
```
