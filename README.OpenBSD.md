# OpenBSD-specific notes

These information apply to OpenBSD. Feel free to contribute and add instructions for other BSD distribution if general information found in the [main Readme](README.md) do not directly apply.

## Global configuration

* Download and install the following tools from the OpenBSD packages directory :

		$ export PKG_PATH=http://ftp.openbsd.org/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/
    	$ pkg_add -i jre jdk cmake git subversion boost gcc g++ emacs tcl tk

	Make sure, when choice is offered, to install the latest version available of these tools, as required in the [main Readme](README.md). _Please note that default gcc version included in OpenBSD is too old for Mozart to compile._
* The directory layout suggested in [main Readme](README.md) will be assumed here.

## Compilation of Gtest
1. Download Gtest in your `<projects>/externals/gtest` directory as suggested in the [main Readme](README.md).
1. In your terminal, launch Gtest compilation by typing :

		$ cd <projects>/builds/gtest-debug
		$ cmake -DCMAKE_C_COMPILER="egcc" -DCMAKE_CXX_COMPILER="eg++" -DCMAKE_BUILD_TYPE=Debug ../../externals/gtest
	    $ make

	Note that the recent gcc you have installed is identified by `egcc` on OpenBSD and no confusion must be made to avoid compilation errors.

## Compilation of LLVM
1. Download LLVM in your `<projects>/externals/llvm` directory as suggested in the [main Readme](README.md).
1. In your terminal, launch LLVM compilation by typing :

		$ cd <projects>/builds/llvm-release
		$ cmake -DCMAKE_C_COMPILER="egcc" -DCMAKE_CXX_COMPILER="eg++" -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" ../../externals/llvm
	    $ make

   Please note that compilation may fail due to resource limitation. Use `ulimit` to temporarily change these values.

## Compilation of Mozart 2
1. Download Mozart in your `<projects>/mozart2` directory as suggested in the [main Readme](README.md).
1. In your terminal, launch Mozart compilation by typing :

		$ cd <projects>/builds/mozart2-release
		$ cmake -DCMAKE_C_COMPILER="egcc" -DCMAKE_CXX_COMPILER="eg++" -DCMAKE_BUILD_TYPE=Release -DGTEST_SRC_DIR=../../externals/gtest -DGTEST_BUILD_DIR=../gtest-debug -DLLVM_SRC_DIR=../../externals/llvm -DLLVM_BUILD_DIR=../llvm-release -DCMAKE_CXX_FLAGS="-I/usr/local/include -I/usr/local/include/c++/4.8.2 -I/usr/local/include/c++/4.8.2/x86_64-unknown-openbsd5.5 -I/usr/X11R6/include -pthread -O3" -DCMAKE_INSTALL_PREFIX=../../redist ../../mozart2
		$ make

	__Replace `4.8.2` and `x86_64-unknown-openbsd5.5` by the folders corresponding to your gcc installation.__ You may need to add parameter `-DCMAKE_CXX_LINK_FLAGS="-latomic"` on some versions if linking fails with undefined references.

1. To copy all the binaries in the `redist` folder, type :

		$ make install