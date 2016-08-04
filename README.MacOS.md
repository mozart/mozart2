# Setup a build environment on Mac OS

## Required software

In order to build the system on MacOS you need at least the 10.8 version of the operating system. This is very important because the C++ compiler shipped with earlier version will fail (there are no proper C++11 headers and limited libc++ support).

Download and install the following tools:

*  [Mac OS development tools](http://developer.apple.com)
*  [Homebrew](http://mxcl.github.com/homebrew/).
*   Any emacs distribution, for instance [Aquamacs](http://aquamacs.org/).

### Homebrew cask

In case you don't have plans to work on Mozart 2, you can simply install it as
a compiled binary via [Homebrew cask] (if you have Homebrew installed you're
already set up):

```shell
brew tap dskecse/tap
brew cask install mozart2
```

[Homebrew cask]: https://caskroom.github.io/

### Homebrew formula

You can easily build Mozart 2 with Homebrew if you just want to install directly from the git repository.
If you want to work on Mozart 2, follow instructions in the next section instead.

```shell
brew tap eregon/mozart2
brew install --HEAD mozart2
```

If something goes wrong, it might be intersting to check the contents of the logs
in `~/Library/Logs/Homebrew/llvm_for_mozart2` and `~/Library/Logs/Homebrew/mozart2`.

### Installing dependencies

*  Install CMake if you do not have it already: `brew install cmake`
*  Install the boost libraries: `brew install boost --c++11` (compare the version with the one in [README.md](README.md#requirements)).
*  Install *llvm* and *clang*. You need to keep note of the directory containing the sources and the one containing the built files.

The most common problem on OS X is to not build using `libc++`, which is required for proper C++11 support.
One needs therefore to pass specific `CMAKE_CXX_FLAGS` as written below.

Depending on the OS X version the location of C++11 headers changes:

* OS X 10.6 and 10.7: `/usr/lib/c++/v1`
* OS X 10.8: `/Library/Developer/CommandLineTools/usr/lib/c++/v1`

Replace `<CXX11_HEADERS>` below by this path.

```
    $ curl -O http://llvm.org/releases/3.2/llvm-3.2.src.tar.gz
    $ tar xvfz llvm-3.2.src.tar.gz && mv llvm-3.2.src llvm
    $ cd llvm/tools
    $ curl -O http://llvm.org/releases/3.2/clang-3.2.src.tar.gz
    $ tar xvfz clang-3.2.src.tar.gz && mv clang-3.2.src clang
    $ cd ../../ && mkdir build-llvm && cd build-llvm
    $ cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_CXX_FLAGS="-stdlib=libc++ -I<CXX11_HEADERS>" \
            -DCMAKE_BUILD_TYPE=Release ../llvm
    $ make     
```      
We will refer to `LLVM_SOURCES` and to `LLVM_BUILD` whenever we refer to the sources and the build directories of LLVM.

## Building
With all the dependencies installed you can do:

```
    $ git clone --recursive https://github.com/mozart/mozart2.git
    $ mkdir build && cd build
    $ cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_CXX_FLAGS="-stdlib=libc++ -I<CXX11_HEADERS>" \
            -DLLVM_SRC_DIR=LLVM_SOURCES -DLLVM_BUILD_DIR=LLVM_BUILD \
            -DCMAKE_BUILD_TYPE=Release ../mozart2
    $ make -j `sysctl -n hw.ncpu`
    $ make install
``` 

## Common problems
If you already have any of the dependencies installed chances are that they were linked against *libstdc++* and this will produce errors during the build process. That is mostly the case if you already had a Boost distribution installed. In that case please reinstall them or build them in another place and **be sure** that during the build process the *right* ones are chosen.
