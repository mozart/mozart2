# Example app based on Mozart2 and its bootcompiler

This is a trivial example application, whose only purpose is to show how to actually use the [Mozart2 VM](https://github.com/mozart/mozart2) and its [bootstrap compiler](https://github.com/mozart/mozart2-bootcompiler).

## Build instructions

The first time, prepare your build environment with:

    experiment$ mkdir build
    experiment$ cd build
    build$ cmake -D MOZART_DIR=/path/to/mozart2 \
        -D BOOTCOMPILER_DIR=/path/to/mozart2-bootcompiler ..

When that has been done one, you can build with:

    build$ make

## To run the generated program

    build$ ./testmozart
