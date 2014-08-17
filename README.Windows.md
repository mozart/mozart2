# Windows-specific notes

General information can be found in the [main Readme](README.md). Unless
otherwise specified here, instructions found in the main Readme apply.

## Global configuration
### Development tools
Download and install the following tools:

*   Java (required for building the boot compiler)
*   Python (required for building LLVM)
*   Git for Windows
*   CMake >= 2.8.6
*   A recent 32-bit (i686) or 64-bit (x86_64) targeting [MinGW-64 distro](http://mingw-w64.sourceforge.net/download.php#mingw-builds) with gcc >= 4.7.1. 

These tools won't be needed at run time. We will refer to the installation directory of MinGW (in which the first `bin` subdirectory is found) by `<mingw>`. 
All commands in this file are to be done in the MinGW terminal (shortcut available from the start menu).

### Mozart requirements
Download and install :

*   Emacs for Windows
*   32-bit or 64-bit (depending on MinGW) [Active Tcl](http://www.activestate.com/activetcl/downloads) or self-compiled Tcl/Tk >= 8.5

We will refer to the installation directory of Emacs and Tcl/Tk by `<emacs>` and `<tcl>`, respectively.

### Suggested directory layout

We suggest that you use the following directory layout, starting from a
directory `<projects>` :

	<projects>
	  + mozart2              // cloned from this repo
	  + externals
	      + boost            // source of Boost (see below)
	      + gtest            // source of GTest (see below)
	      + llvm             // source of LLVM (see below)
	  + builds
	      + gtest            // build of GTest
	      + llvm             // build of LLVM
	      + mozart2          // build of Mozart
	  + redist               // export dir of Mozart (see below)

Throughout the following instructions, we will assume this layout.

## Compilation of Boost
1. Download [Boost **>= 1.53**](http://www.boost.org/users/download/) and extract the archive in `<projects>\externals\boost`.
1. In your MinGW terminal, type (`<arch>` depends on building 32-bit or 64-bit target) :

		C:> cd <projects>\externals\boost\tools\build\src\engine
		C:> build.bat mingw
		C:> cp bin.nt<arch>\*.* ..\..\..\..\
		C:> cd ..\..\..\..\
		C:> bjam --toolset=gcc

1. From `<projects>\externals\boost`, copy `boost` subdirectory in your `<mingw>\<arch>-w64-mingw32\include` directory and merge `stage\lib` subdirectory with your `<mingw>\<arch>-w64-mingw32\lib` directory.

## Compilation of GTest

1. Download [GTest](https://code.google.com/p/googletest/downloads/list) and extract the archive in `<projects>\externals\gtest`.
1. In your MinGW terminal, type :

		C:> cd <projects>\builds\gtest
		C:> cmake -G"MinGW Makefiles" ..\..\externals\gtest
		C:> mingw32-make

## Compilation of LLVM
1. Download [LLVM and Clang **3.3**](http://llvm.org/releases/download.html#3.3) source code.
1. Extract the content of LLVM source archive in `<projects>\externals\llvm` and the content of Clang source archive in `<projects>\externals\llvm\tools\clang`.
1. If you are targeting 64-bit builds, patch the files `<projects>\externals\llvm\lib\ExecutionEngine\JIT\JIT.cpp` and `<projects>\externals\llvm\lib\ExecutionEngine\MCJIT\SectionMemoryManager.cpp` by replacing :

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

		C:> cd <projects>\builds\llvm
		C:> cmake -G"MinGW Makefiles" -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release ..\..\externals\llvm
		C:> mingw32-make

## Compilation of Mozart 2
1. In your MinGW terminal, type :

		C:> set PATH=%PATH%;<projects>\builds\llvm\bin;<emacs>\bin;<tcl>\bin
		C:> cd <projects>
		C:> git clone --recursive https://github.com/mozart/mozart2.git
		C:> cd <projects>\builds\mozart2
		C:> cmake -G"MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_DIR=..\llvm -DGTEST_BUILD_DIR=..\gtest -DGTEST_SRC_DIR=..\..\externals\gtest -DLLVM_SRC_DIR=..\..\externals\llvm -DBOOST_ROOT=..\..\externals\boost\  -DCMAKE_INSTALL_PREFIX=..\..\redist\ ..\..\mozart2
		C:> mingw32-make

	If the script does not detect correctly where MinGW is installed, you can tell
	it using the option `-DMINGW_ROOT=<mingw>`. Similarly, if the version of GCC in
	your MinGW is not 4.9.1, you can tell it with
	`-DMINGW_COMPILER_VERSION=4.8.2`, e.g.

1. To copy all the binaries in the `redist` folder, type :	

		C:> mingw32-make install

## Running Mozart 2

For Mozart to run properly, you need to ensure :

* Tcl/Tk is in your PATH or its `lib` and `bin` subfolders are merged with Mozart ones
* An environment variable `OZEMACS` is set to `<emacs>\bin\runemacs.exe`
