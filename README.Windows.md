# Windows-specific notes

General information can be found in the [main Readme](README.md). Unless
otherwise specified here, instructions found in the main Readme apply.

## Prerequisites
In addition to what is specified in the main README download and install the following tools:

*   [Inno Setup](http://www.jrsoftware.org/isdl.php) (with preprocessor, required for building setup files)
*   A recent 32-bit (i686) or 64-bit (x86_64) targeting [MinGW-64 distro](http://mingw-w64.sourceforge.net/download.php#mingw-builds) with gcc >= 4.7.1.

These tools won't be needed at run time. We will refer to the installation directory of MinGW (in which the first `bin` subdirectory is found) by `<mingw>`.
Unless specified, all commands in this file are to be done in the MinGW terminal (shortcut available from the start menu).

## Specific tools

We will assume for that you use the following directory layout, starting from
the root :

	<projects>
	  + mozart2              // cloned from this repo
	      + build	         // build of Mozart
	  + tcl-release		 // source of tcl (see below)
	  + tk-release           // source of tk (see below)
	  + boost	         // boost downloaded
	<tcltk>			 // directory in which we install tcl and tk

We recommend to use a self-compiled Tcl/Tk. You can however use [Active Tcl](http://www.activestate.com/activetcl/downloads)

### Tcl

    C:> cd C:\projects
    C:> wget -O tcl-release.tar.gz https://github.com/tcltk/tcl/archive/release.tar.gz
    C:> tar xf tcl-release.tar.gz
    C:> cd tcl-release/win/
    C:> bash configure --enable-threads --enable-64bit --prefix=C:/tcltk/
    C:> make
    C:> make install

### Tk

    C:> cd C:\projects
    C:> wget -O tk-release.tar.gz https://github.com/tcltk/tk/archive/release.tar.gz
    C:> tar xf tk-release.tar.gz
    C:> cd tk-release/win/
    C:> bash configure --enable-64bit --prefix=C:/tcltk/ --with-tcl=../../tcl-release/win/
    C:> make
    C:> make install

### Boost

Once you downloaded boost, you need to install different modules.

    C:> cd C:\projects\boost
    C:> call bootstrap.bat gcc
    C:> .\b2 toolset=gcc variant=release --with-thread --with-system --with-random --with-filesystem --with-program_options

### Emacs

The packaging manager we use, installs all the program used to install Emacs in
its package. Which means, if you use MingW to install Emacs directly with
pacman, you will include all MingW in your package. As a consequence, we
decided to install Emacs with a lighter package manager :
[chocolatey](https://chocolatey.org/). You can
just run the following in a classic Windows prompt, in PowerShell :

    C:> choco install emacs64

You can install emacs with MingW, it will just make your package heavy.

## Build

Mozart 2 is built with cmake. We add two CMake options to prepare the package :

* `-DISS_INCLUDE_EMACS=ON` will include your Emacs files in the package.
* `-DISS_INCLUDE_TCL=ON` will include your Tcl/Tk files in the package.

The following steps will perform the build :

    C:> mkdir C:\projects\mozart2\build
    C:> cd C:\projects\mozart2\build
    C:> cmake -DCMAKE_BUILD_TYPE=Release -G"MSYS Makefiles" -DCMAKE_PREFIX_PATH=C:\tcltk -DBOOST_ROOT=C:\projects\boost -DISS_INCLUDE_TCL=ON -DISS_INCLUDE_EMACS=ON C:\projects\mozart2
    C:> make install

### Installer

You can create an installer with the following command :

    C:> cmake --build . --target installer -- VERBOSE=1

The installer can be found in C:\projects\mozart2\build.

## Running Mozart 2

For Mozart to run properly, you need to ensure :

* Tcl/Tk is in your PATH or its `lib` and `bin` subfolders are merged with
Mozart ones
* An environment variable `OZEMACS` is set to `<emacs>\bin\runemacs.exe`

Both should be set automatically with the created installer.

## Compilation of LLVM
If you want to build the pre-generated sources, you will need to install LLVM.
To do so, you can follow the instructions below and then check the main README
for information on how to build the pre-generated sources.
1. Download [LLVM and Clang
   **3.3**](http://llvm.org/releases/download.html#3.3) source code.
1. Extract the content of LLVM source archive in `C:\projects\externals\llvm`
   and the content of Clang source archive in
`C:\projects\externals\llvm\tools\clang`.
1. If you are targeting 64-bit builds, patch the files
   `C:\projects\externals\llvm\lib\ExecutionEngine\JIT\JIT.cpp` and
`C:\projects\externals\llvm\lib\ExecutionEngine\MCJIT\SectionMemoryManager.cpp`
by replacing :

    	// Determine whether we can register EH tables.
		#if (defined(__GNUC__) && !defined(__ARM_EABI__) && \
		     !defined(__USING_SJLJ_EXCEPTIONS__))
		#define HAVE_EHTABLE_SUPPORT 1
		#else
		#define HAVE_EHTABLE_SUPPORT 0
		#endif

	by :

    	// Determine whether we can register EH tables.
		#if (defined(__GNUC__) && !defined(__ARM_EABI__) && \
		     !(defined(__USING_SJLJ_EXCEPTIONS__) || defined(_WIN64)))
		#define HAVE_EHTABLE_SUPPORT 1
		#else
		#define HAVE_EHTABLE_SUPPORT 0
		#endif

1. In your MinGW terminal, type :

		C:> cd C:\projects\builds\llvm
		C:> cmake -G"MinGW Makefiles" -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release ..\..\externals\llvm
		C:> mingw32-make

## Compilation of GTest

1. Download [GTest](https://code.google.com/p/googletest/downloads/list) and
   extract the archive in `C:\projects\externals\gtest`.
1. In your MinGW terminal, type :

		C:> cd C:\projects\builds\gtest
		C:> cmake -G"MinGW Makefiles" ..\..\externals\gtest
		C:> mingw32-make
