# Setup a build environment on Mac OS

Depending on the version of your system, the build is quite different.

## Required software

Download and install the following tools:

*  [Mac OS development tools](http://developer.apple.com)
*  [Homebrew](http://mxcl.github.com/homebrew/)
*  Any emacs distribution, for instance [Aquamacs](http://aquamacs.org/)

Install CMake if you do not have it already: `brew install cmake`

# Full clang build with MacOS >= 10.8

### Installing dependencies

*  Install the boost libraries: `brew install boost --with-c++11`
*  Install *llvm* and *clang*. You need to keep note of the directory containing the sources and the one containing the built files. You can use: 

```
    $ curl -O http://llvm.org/releases/3.2/llvm-3.2.src.tar.gz
    $ tar xvfz llvm-3.2.src.tar.gz && mv llvm-3.2.src llvm
    $ cd llvm/tools
    $ curl -O http://llvm.org/releases/3.2/clang-3.2.src.tar.gz
    $ tar xvfz clang-3.2.src.tar.gz && mv clang-3.2.src clang
    $ cd ../../ && mkdir build-llvm && cd build-llvm
    $ cmake -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_FLAGS="-stdlib=libc++ -I/usr/lib/c++/v1/" \
            -DCMAKE_BUILD_TYPE=Release   ../llvm
    $ make -j `sysctl -n hw.ncpu`
```

We will refer to LLVM_SOURCES and to LLVM_BUILD whenever we refer to the sources directory of llvm and the build directory reap.

## Building
With all the dependencies installed you can do:

```
    $ git clone --recursive https://github.com/mozart/mozart2.git
    $ mkdir build && cd build
    $ cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
            -DLLVM_SRC_DIR=LLVM_SOURCES -DLLVM_BUILD_DIR=LLVM_BUILD \
            -DCMAKE_BUILD_TYPE=Release ../mozart2/
    $ make
    $ make install
``` 

## Common problems
If you already have any of the dependencies installed chances are that they were linked against *libstdc++* and this will produce errors during the build process. That is mostly the case if you already had a boost distribution installed. In that case please reinstall them or build them in another place and **be sure** that during the build process the *right* ones are chosen.


# GCC build with MacOS < 10.8

### Installing dependencies

On earlier version of OS X you can install a recent GCC and compile mozart with it.
It is much easier to install than LLVM/clang with libc++ support.

* Install gcc 4.7 with `brew tap homebrew/versions` and `brew install gcc47`

You need an adapted formula to compile boost with C++11 support for older versions of OS X.
Unfortunately the current (2013-06-01) Homebrew Formula restricts C++11 support to Lion or later.
So download [this formula](https://gist.github.com/eregon/5690812) and replace `/usr/local/Library/Formula/boost.rb`
(I might add a Homebrew Tap later).

* Unlink boost if already installed and linked: `brew unlink boost`
* You can now install the boost libraries: `brew install boost --with-c++11`


*  Install *llvm* and *clang*. You need to keep note of the directory containing the sources and the one containing the built files. You can use: 

```
    $ curl -O http://llvm.org/releases/3.2/llvm-3.2.src.tar.gz
    $ tar xvfz llvm-3.2.src.tar.gz && mv llvm-3.2.src llvm && rm llvm-3.2.src.tar.gz
    $ cd llvm/tools
    $ curl -O http://llvm.org/releases/3.2/clang-3.2.src.tar.gz
    $ tar xvfz clang-3.2.src.tar.gz && mv clang-3.2.src clang && rm clang-3.2.src.tar.gz
```

You need to patch clang to include the C++11 headers of libstdc++:
Ensure you are in `src/llvm/tools/clang`, and

```
    $ curl https://gist.github.com/eregon/5690821/raw/9f69de4c16fb130ca2006dffcd4b80068b9e954c/0001-add-Homebrew-GCC-4.7-path.patch | patch -p1
```

Now you can compile LLVM and Clang:

```
    $ cd ../.. && mkdir build-llvm && cd build-llvm
    $ CC=gcc-4.7 CXX=g++-4.7 cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD:STRING=X86 ../llvm
    $ make -j `sysctl -n hw.ncpu`
```

We will refer to LLVM_SOURCES and to LLVM_BUILD whenever we refer to the sources directory of llvm and the build directory resp.

## Building
With all the dependencies installed you can do:

```
    $ git clone --recursive https://github.com/mozart/mozart2.git
    $ mkdir build && cd build
    $ cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_COMPILER=/usr/local/bin/g++-4.7 \
            -DLLVM_SRC_DIR=LLVM_SOURCES -DLLVM_BUILD_DIR=LLVM_BUILD \
            ../mozart2/
    $ make
    $ make install
```
