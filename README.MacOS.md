# Setup a build environment on Mac OS

## Required software

In order to build the system on MacOS you need at least the 10.8 version of the operating system. This is very important because the C++ compiler shipped with earlier version will fail.

Download and install the following tools:

*  [Mac OS development tools](http://developer.apple.com)
*  [Homebrew](http://mxcl.github.com/homebrew/).
*   Any emacs distribution, for instance [Aquamacs](http://aquamacs.org/).

### Installing dependencies

*  Install CMake if you do not have it already: `brew install cake` 
*  Install the boost libraries: `brew install boost --with-c++11`.
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
    $ make     
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
