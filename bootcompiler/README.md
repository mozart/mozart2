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
    bootcompiler$ sbt package

## Usage

See [sjrd/mozart-app-test](https://github.com/sjrd/mozart-app-test) for an integrated way of using this bootcompiler.

Roughly, the program must be executed with exactly 2 command-line arguments: the .oz file to process, and the .cc file to output.

For example:

    $ scala "./target/scala-2.9.1/bootcompiler_2.9.1-2.0-SNAPSHOT.jar" \
        Input.oz output.cc

The file `Input.oz` must contain an Oz _statement_. The generated program will execute that statement.

## See also ##

*   [Mozart-Oz v2](https://github.com/mozart/mozart2)
