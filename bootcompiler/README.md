Mozart-Oz bootstrap compiler
----------------------------

This is the bootstrap compiler for [Mozart-Oz v2](https://github.com/mozart/mozart2). The complete Oz compiler is written itself in Oz, which makes bootstrapping an issue. This compiler is a naive compiler that we use to compile the complete Oz compiler.

For this reason, a design goal of this bootstrap compiler is to stay minimal. In particular, we will not attempt to perform any optimization of the resulting code.

## Dependencies

*   [Scala](http://www.scala-lang.org/)
*   [SBT](https://github.com/harrah/xsbt/wiki/Getting-Started-Setup) for the build process

## Build instructions

    projects$ git clone git://github.com/mozart/mozart2-bootcompiler.git bootcompiler
    projects$ cd bootcompiler
    bootcompiler$ sbt one-jar

## Usage

See [sjrd/mozart-app-test](https://github.com/sjrd/mozart-app-test) for an integrated way of using this bootcompiler.

Roughly, the program must be executed with 4 kinds of command-line arguments (that can be repeated, except for the first one):

*   Under option `-o`, the output file (a `.cc` file),
*   Under option `-m`, a path to a file or directory where it can find builtin information,
*   Under option `-b`, a path to a functor that must be part of the base environment,
*   A list of `.oz` files containing the functors of the application (the first one being the main functor).

Normally you need two base functors: the file `Base.oz` which contains the regular base environment of Oz; and the file `BootBase.oz` which contains only the boot module manager.

In the list of regular functors, you must give all the system functors used by the application, so that they can be linked in.

For example:

    $ java -jar "./target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT-one-jar.jar" \
        -o output.cc \
        -m "/path/to/mozart/build/boostenv/main/" \
        -b "/path/to/mozart/lib/base/Base.oz" \
        -b "/path/to/mozart/lib/boot/BootBase.oz" \
        Main.oz SomeOtherFunctor.oz \
        "/path/to/mozart/lib/sys/System.oz" # and others

The generated program will (lazily) load all the given functors, and request the main one (effectively executing the instructions therein).

## See also ##

*   [Mozart-Oz v2](https://github.com/mozart/mozart2)
