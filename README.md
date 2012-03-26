# Mozart-Oz v2

This is a clean reimplementation of the Mozart virtual machine.


## Build instructions

    mozart$ mkdir build
    mozart$ cd build/
    build$ cmake ..
    build$ make

This generates two "products":

* `vm/main/libmozartvm.a`, which is the VM library
* `vm/test/vmtest`, which is an executable that runs unit tests


## Run the unit tests

build$ vm/test/vmtest


## Run an Oz program

In the current stage of development, the VM cannot load programs, e.g., `.ozf`
files. Only the VM library is available.

If you want to experiment with actual Oz statements (which is likely), you
should use the
[bootstrap compiler](https://github.com/mozart/mozart2-bootcompiler).

We also provide
[a small testing environment](https://github.com/sjrd/mozart-app-test) in which
you can easily write Oz code, compile it with the bootstrap compiler, and run
it with the VM library. This is the recommended entry point for experimenting
with Mozart2.
