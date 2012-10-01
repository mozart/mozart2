Mozart-Oz bootstrap compiler
----------------------------

This is the bootstrap compiler for [Mozart-Oz v2](https://github.com/mozart/mozart2). The complete Oz compiler is written itself in Oz, which makes bootstrapping an issue. This compiler is a naive compiler that we use to compile the complete Oz compiler.

For this reason, a design goal of this bootstrap compiler is to stay minimal. In particular, we will not attempt to perform any optimization of the resulting code.

## Getting the sources

You will need a [Git](http://git-scm.com/) client to fetch the sources.

    projects$ git clone git://github.com/mozart/mozart2-bootcompiler.git

## Build instructions

    projects$ cd mozart2-bootcompiler
    mozart2-bootcompiler$ ./sbt one-jar

## Usage

See [sjrd/mozart-app-test](https://github.com/sjrd/mozart-app-test) for an integrated way of using this bootcompiler.

The bootcompiler has 3 modes:

*   Module (default): compiles a .oz file containing a functor
*   BaseEnv (`--baseenv`): compiles the base environment
*   Linker (`--linker`): compiles a linker for one to many compiled functors

An entire program that must be built with the bootcompiler must call the BaseEnv mode once, the Module mode once per source `.oz` file, and the Linker mode once.

The resulting `.cc` must all be compiled and linked together in one executable.

All modes support zero to many `-D` arguments that specify initial conditional defines for `\ifdef`'s.

### The BaseEnv mode

The BaseEnv mode is used to compile the base environment. It yields a `.cc` file that executes the statements necessary to 1) create the base environment and 2) register the boot modules and the base modules in the boot module manager. It also generates a file describing the features exported by the base environment, to be used by the other modes.

This mode should be called as follows:

    $ java -jar "./target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar" \
        --baseenv
        -o "/path/to/output/Base.cc"
        -h "boostenv.hh"
        -m "/path/to/mozart/build/boostenv/main/"
        -b "/path/to/output/baseenv.txt"
        "/path/to/mozart/lib/base/Base.oz" \
        "/path/to/mozart/lib/boot/BootBase.oz"

The files `Base.oz` and `BootBase.oz` will be compiled together as base functors. Declarations made by `Base.oz` are visible in `BootBase.oz`, but not the reverse.

Information about the features exported by the base functors will be written to `baseenv.txt`.

### The Module mode

The Module mode must be called once for each non-base functor. It yields a `.cc` file that registers the functor in the boot module manager.

This mode should be called as follows:

    $ java -jar "./target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar" \
        -o "/path/to/output/FunctorName.cc"
        -h "boostenv.hh"
        -m "/path/to/mozart/build/boostenv/main/"
        -b "/path/to/output/baseenv.txt"
        "/path/to/source/FunctorName.oz"

### The Linker mode

The Linker mode generates a `.cc` file to link them all. This `.cc` file contains a `main()` procedure.

This mode should be called as follows:

    $ java -jar "./target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar" \
        --linker
        -o "/path/to/output/LinkerMain.cc"
        -h "boostenv.hh"
        -m "/path/to/mozart/build/boostenv/main/"
        -b "/path/to/output/baseenv.txt"
        "/path/to/source/MainFunctor.oz"
        "/path/to/source/FunctorName1.oz"
        ...
        "/path/to/source/FunctorNameN.oz"

The listed functors will all be linked together, and the resulting program will force the application of the main functor (the first listed), effectively executing the instructions therein.

## See also ##

*   [Mozart-Oz v2](https://github.com/mozart/mozart2)
